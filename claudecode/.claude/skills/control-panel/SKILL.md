---
name: control-panel
description: Operate remote GPU machines via the ControlPanel HTTP API - exec commands, manage containers, init environments, launch long-running services. Trigger on "ControlPanel", "面板", "操作机器", or when working with machines registered in the panel.
user-invocable: true
---

# ControlPanel 远程机器操作

通过 ControlPanel 的 HTTP API 管理远程 GPU 服务器：执行命令、创建容器、初始化环境、启动推理服务等。完整 API 文档用户应该提供，如果没有提供可以看看路径 `/tmp-data/ControlPanel/docs/API.md` 或者 `~/Projects/ControlPanel/docs/API.md`，本 skill 仅仅是实战经验提炼，始终应该查看API原文去获取最新且更精准的操作手册。

## 认证（第一步先做这个）

认证是 **API key**（`Authorization: Bearer cpk-...`），key 由用户提供，没有向用户询问，：

```bash
BASE=http://<ip>:<port>
AUTH="Authorization: Bearer cpk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

curl -s $BASE/api/about                      # 免认证，确认连对服务
curl -s -H "$AUTH" $BASE/api/auth/status     # 验证 key：应为 {"loggedIn":true,"role":"admin","via":"key",...}
```

- 除 `GET /api/about` 外**所有请求都要带 `-H "$AUTH"`**——包括 GET、runs 轮询、指标读取，漏带就是 401。
- `401` = key 缺失/无效/过期 → 向用户索要新 key。没有自助取回，**不要尝试猜凭证**。
- `403` = 权限不够（guest key 打了 admin 端点；exec/fs/一切写操作都要 admin）→ 找用户换 admin key。
- 长任务跨天时 key 可能中途过期（再次 401），找用户续一把即可。

## 常用调用模式

先确认服务在线、选机器：

```bash
curl -s $BASE/api/about                                                            # 免认证探活
curl -s -H "$AUTH" $BASE/api/servers | jq -r '.[] | [.id, .gpu_summary] | @tsv'    # 机器清单，按 GPU 型号选
curl -s -H "$AUTH" $BASE/api/servers/<id>/metrics | jq '[.gpus[] | (.memory_used_mb*100/.memory_total_mb|floor)]'  # GPU 空闲度
```

### Exec：命令执行的引号阶梯（最重要经验）

嵌套引号（JSON → 远端 shell → docker bash -c → 内层）是最大坑。按复杂度选层级：

```bash
# 1) 简单命令：jq --arg 构造 body，不手拼json
curl -s -X POST $BASE/api/servers/<id>/exec -H "$AUTH" -H 'Content-Type: application/json' \
  --data "$(jq -n --arg c 'sudo docker ps' '{command: $c, timeout_sec: 60}')"

# 2) 复杂命令/小脚本：script_b64（面板在目标机以 bash -s 执行）
#    ⚠️ 解码后上限 2048 字节，超限会静默失败/413
SCRIPT='for i in 1 2 3; do echo "row $i 引号无坑"; done'
curl -s -X POST $BASE/api/servers/<id>/exec -H "$AUTH" -H 'Content-Type: application/json' \
  --data "$(jq -n --arg s "$(printf %s "$SCRIPT" | base64 -w0)" '{script_b64: $s, timeout_sec: 60}')"

# 3) 大脚本：先 fs/raw 上传（path 要百分号编码），再 bash 执行
curl -s -X PUT --data-binary @/tmp/job.sh -H "$AUTH" \
  "$BASE/api/servers/<id>/fs/raw?path=%2Ftmp%2Fjob.sh"
curl -s -X POST $BASE/api/servers/<id>/exec -H "$AUTH" -H 'Content-Type: application/json' \
  --data "$(jq -n '{command: "bash /tmp/job.sh", timeout_sec: 300}')"
```

判断响应：`exit_code == 0 && error == null` 才算成功；`timed_out: true` 且 `exit_code: null` 是超时被杀（已产出的 stdout 会返回，不丢）。本机写好的大脚本可以先用 `Write` 工具落盘再上传。

### 长任务：runs 通道

`exec` 的请求生命周期 = 命令生命周期（断连即杀）。镜像 pull、服务启动、长时间编译这类任务用 runs：

```bash
curl -s -X POST $BASE/api/runs -H "$AUTH" -H 'Content-Type: application/json' \
  --data "$(jq -n '{command: "sudo docker pull <img>", server_ids: ["<id>"], timeout_sec: 0}')"   # 0/缺省=不限时
# stdout 实时增长，status 到终态结束
curl -s -H "$AUTH" $BASE/api/runs/<run_id> | jq '{status, results: [.results[] | {exit_code, error}]}'
```

## 容器标准流程

### 1. 建容器前先看

- `sudo -n true` 探测免密 sudo（集群机器一般免密）
- `sudo docker images` —— **本机镜像优先**（30-48GB 的大镜像能不 pull 就不 pull；pull 前先查，已有的 tag pull 只做增量校验，很快）
- `sudo docker ps -a --format '{{.Names}}'` 查重，容器名用独特前缀 `gogongxt-<task>`
- `nvidia-smi` + `ss -ltn` 看显存和端口占用（host 网络模式下端口全机共享）
- **共享机器红线**：别人的容器未经允许不要乱动（不 stop/rm/exec）；`docker ps` 里有大量他人容器是常态

### 2. 标准容器模板

```bash
sudo docker run -itd --network=host --privileged --ulimit memlock=-1 --ipc=host --cap-add=ALL \
  -v /etc/localtime:/etc/localtime:ro -v /sys/fs/cgroup:/sys/fs/cgroup:ro --ulimit stack=67108864 \
  -v /data:/data -v /data0:/data0 -v /data1:/data1 -v /data2:/data2 -v /data3:/data3 -v /mnt/common:/mnt/common \
  --shm-size 512G -e NVIDIA_VISIBLE_DEVICES=all --gpus all \
  --entrypoint /bin/bash --name gogongxt-<task> <image>
```

### 3. 挂个人 NFS（每个新容器都要重挂，per-container fuse 挂载）

```bash
sudo docker exec <name> bash -c 'cd /tmp && curl -sL https://s3-nmgpu-inter.didistatic.com/gogongxt-dev/ofs_v1_0_42.tar -o ofs.tar \
  && tar -xf ofs.tar && cd v1.0.42 && bash ./script/ofs_mount.sh gogongxt /nfs/gogongxt d261a28ee50545e29bd7ff2c5ccb2759 hbbpussd'
# 成功标志：===== Volume[gogongxt] mounted to Path[/nfs/gogongxt] success =====（中间的 stat 报错是正常噪音）
# 验证：ls /nfs/gogongxt/
```

### 4. 基础初始化（挂好 NFS 之后）（可选）

初始化只是为了安装一些tmux，zsh，gh，yq等方便用户登录机器开发的包，不影响核心的任务执行

因为一般镜像里面都已经有了torch，nvcc等，所以初始化操作如果用户没有提，可以跳过

```bash
sudo docker exec <name> bash /nfs/gogongxt/luban_scripts/docker_init_env.sh --proxy 10.191.16.35:7891
```

个别工具在 NFS 缺失报 Error 不致命。10.191.16.35:7891 是通用代理，容器要访问外网（GitHub 等）走它。然后这里的代理的地址也不一定完全正常可用，如果需要基础初始化但是网络访问不通，可以暂停告知用户

## 启动推理服务（sglang/vllm 等）的模式

### 往容器里写文件：docker exec -i + heredoc（无引号嵌套）

```bash
sudo docker exec -i <name> bash -c 'cat > /root/launch.sh && chmod +x /root/launch.sh' <<'EOS'
#!/bin/bash
exec env CUDA_VISIBLE_DEVICES=0,1,2,3 /usr/bin/python3 /usr/local/bin/sglang serve ...
EOS
```

### 后台启动 + 日志过滤

宿主机的 `/data*` 子目录可能有root权限问题，**日志放容器内**（如 `~/logs/`）最稳：

```bash
sudo docker exec <name> bash -c 'nohup ~/logs/....sh > >(grep -vE "\"GET /(metrics|health)" > ~/logs/....log) 2>&1 & echo PID=$!'
```

`> >(...)` 进程替换做日志过滤，nohup + `&` 脱离 exec 会话存活。

### 健康轮询（要给足耐心）

```bash
for i in $(seq 1 50); do
  sleep 10
  P=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:<port>/health)
  echo "round$i: health=$P"; [ "$P" = 200 ] && break
done
```

- **首次启动慢是正常的**：flashinfer/deepgemm 等后端首次要 JIT 编译，用 `ps aux --sort=-%cpu` 看 cicc、`nvidia-smi` 看显存趋势判断进度
- 服务就绪的标志：health 200 + 日志出现 "The server is fired up and ready to roll"

### 找模型路径

一般用户会指明模型路径，如果没有可以去本地ssd磁盘查找，谨慎在网络挂载盘查找

```bash
timeout 50 find /data /data0 /data1 /data2 /data3 -maxdepth 4 -iname "*<ModelName>*" 2>/dev/null
# 验证：ls <path>/config.json 且有 *.safetensors
# ⚠️ 不要 find /mnt/common（网络盘，会挂死整个命令）
```

## 踩坑清单

以下是一些踩坑历史，方便以后碰到类似问题就知道咋做了

| 坑 | 症状 | 解法 |
|---|---|---|
| 忘带 key / key 过期 | 401 `{"error":...}` | 除 `/api/about` 外所有请求（含 GET、runs 轮询）都带 `-H "$AUTH"`；仍 401 就是 key 过期，找用户续 |
| 权限不够 | 403 | exec / fs / 一切写操作都要 admin key，guest 只读 |
| `script_b64` 超 2048 字节 | 响应为空 / exit=null / 413 | 改用 `fs/raw` 上传后 `bash /tmp/x.sh` |
| 手拼 JSON body | 引号/$ 展开错乱 | 一律 `jq -n --arg` 构造 |
| 引号嵌套（exec→docker bash -c→内层） | 语法错 / `\$` 转义报错 | script_b64 或 fs/raw 上传；容器内写文件用 `docker exec -i ... bash -c 'cat > f' <<'EOS'` |
| find 扫到网络盘 | 命令卡死到超时 | 加 `timeout`；排除网络挂载盘 |
| 宿主机目录写不进（如 `/data1/logs`） | root 也 Permission denied | 日志/脚本放容器内$HOME目录下 |
| 启动脚本日志重定向失败 | nohup 报 No such file，进程秒退 | 先确认日志目录存在再启动 |
| myssh 机器 stderr 丢失 | 错误信息看不到 | `cmd 2>/tmp/e; cat /tmp/e` |
| 一次性容器命令 exit 126 | svensudo 改写容器命令 | 把命令放进 `--entrypoint`，或建容器后 `docker exec` |

## 用完按需清理

容器使用完成后可以根据需求选择是否清理，不清理也没关系

```bash
sudo docker rm -f gogongxt-<task>      # 只删自己前缀的容器
```

要留的数据写 `/data*` 或 NFS，不写容器层。NFS 挂载随容器删除自动消失；容器保留但想释放挂载：容器内 `sudo umount -l /nfs/gogongxt`
