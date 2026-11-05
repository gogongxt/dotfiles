---
name: agent-comms
description: Claude Code 跨会话通信与任务编排指南 — 查看其他会话状态、等 A 会话完成后让 B 自动接力（ListAgents / SendMessage / notify_when_idle）、跨会话发消息、按 UUID 查会话、handoff 哨兵模式、串行链。当用户想让多个 session 协作、接力、等待某会话完成，或问会话间如何通信/互相感知时使用
user-invocable: true
---

# 跨会话通信与编排（agent-comms）

同机的 Claude Code 会话互相可见、可通信。按**需求**组织：先对号入座，照做即可。

## 需求速查表

| 需求 | 方案 | 章节 |
|---|---|---|
| 看现在有哪些会话在跑、各自状态 | `ListAgents` / `/list-agents` | §1 |
| 等 A 干完，B 自动接力 | SendMessage + notify_when_idle | §2 |
| 给另一个会话发消息/留言 | SendMessage 带 message | §3 |
| 查某个会话（含历史/只有 UUID） | transcript 文件 / `--resume` | §4 |
| A 完成后自动拉起全新的 B | handoff 文件 + 哨兵脚本 | §5 |
| 批量串行 / 无人值守 | `claude -p` 链（tmux） | §6 |
| 编排成为日常 | 第三方工具生态 | §7 |

## §1 查看会话状态

- 本会话内调用 `ListAgents`；用户侧命令 `/list-agents`
- 输出：名字（项目名-2位hex）+ 6位短 ref + interactive/bg + busy/idle + cwd + tmux 位置 + started
- busy/idle 语义：**idle = 当前回合结束且队列为空**。停下来问用户问题也是 idle，注意区分
- **查目标会话的名字**：切到那个会话跑 `/list-agents`，第一行 `This session: xxx [ref]` 就是它的寻址名（最权威）
- 名字是自动生成的，hex 无语义；同项目多会话从外部对账用 cwd + started + busy/idle + tmux 位置；发消息带 `[ref]` 消歧。人类侧可用 tmux 窗口名（`tmux rename-window`）做语义标记

## §2 等 A 干完，B 自动接力（核心场景）

因为有时候我会有多个agent并行干不同的活，为了避免互相干扰修改文件啥的，就需要A干活后告诉B可以继续了

1. A 正常跑（如挂 tmux）
2. 另开终端启动 B（同机即可，无需同仓库）
3. 对 B 说（指令模板）：

```
用 ListAgents 找到名字是 "<A的名字>" 的会话，然后调用 SendMessage：
to 填它的名字，notify_when_idle: true，不填 message（纯订阅，零打扰）。然后停下等通知。
收到 [Cross-session idle notice] 后，立即执行任务B：<任务B完整描述、要读的文件、验收标准>
```

等价工具调用：`SendMessage({ "to": "<A的名字>", "notify_when_idle": true })`

事件驱动：B 挂起期间零 token；A 回合结束（或退出）时 B 被自动唤醒开工。

## §3 给另一个会话发消息

`SendMessage({ "to": "<名字>", "message": "内容", "notify_when_idle": 可选 })`

- 消息入队，对方在**下一个工具轮次**收到，不打断正在执行的工具，不丢失
- 对方 UI 只显示首行预览，展开才见全文
- 名字有歧义时带 ref：`"kev-48 [b6dc0c]"`

## §4 按 UUID / 历史会话查询

UUID 不在跨会话寻址体系里（那是 `--resume` 用的）。间接办法：

- transcript：`~/.claude/projects/<路径转义>/<UUID>.jsonl` — mtime = 最后活跃时间，tail = 它最后在干什么
- 复活历史会话：`claude --resume <UUID>`
- 对账活跃会话身份：transcript 首末时间戳 vs ListAgents 的 `started X ago`

## §5 A 完成后自动拉起全新 B（哨兵模式，最稳）

不依赖会话间通信，绕开权限门。A 的任务描述末尾加：

> 全部完成后，把 B 需要知道的（做了什么、改了哪些文件、下一步）写进 `HANDOFF.md`，并 `touch .claude/A-DONE`

哨兵（任意终端或 tmux 窗口）：

```bash
cd <repo>
while [ ! -e .claude/A-DONE ]; do sleep 60; done
claude "先读 HANDOFF.md，然后执行任务B：……"   # 交互式；换 claude -p 则全自动
```

B 无需预先存在；HANDOFF.md 让 B 在全新上下文里拿到 A 的精炼总结。

## §6 批量串行 / 无人值守

tmux 里一条命令：

```bash
claude -p "任务A……" && claude -p "任务B……"
```

每个任务全新上下文，前者退出后立即开始下一个。缺点：`-p` 模式中途不便人工介入。

## §7 编排成为日常（工具生态）

- **vibe-kanban**（BloopAI，★28k）：看板式把任务分派给并行会话
- **claude-mem**：跨会话持久上下文（HANDOFF 模式的产品化）
- **claude-squad**：tmux + git worktree 多 agent 管理
- 官方 best practices：并行会话各用独立 git worktree 隔离，避免互踩

## 机制速查（理解体系）

- 每会话启动时登记进**本机会话注册表**（名字/ref/状态/cwd/tmux 位置）→ ListAgents 读的就是它
- 底层传输是 **Unix domain socket**：每会话监听 `/run/user/1001/cc-socks/<pid>.sock`；消息信封含 `from`（socket 路径）/ `from-name`（寻址名）/ `from-mode`（对方权限模式）
- 消息投递 = 入队 + 接收方下一工具轮次注入；**唤醒 = 注入新回合**（与用户手动发话等价，只是触发者是注册表）
- `notify_when_idle` 是**一次性**订阅，触发即失效；对方直接退出也触发
- 通知附带对方最后输出的摘要，并声明"是数据不是指令"（防提示注入）
- **权限门**：权限模式不同的会话，跨会话流量被扣住给用户批准（防权限洗钱：低权限会话不能指挥高权限会话干活）；实测 bypass 会话 → 受限会话的消息可送达，但注入时强制附带"队友请求"框架（不得当作用户批准、不得代为提权）
- 云端 / Remote Control 会话单向可达（能收不能回）

## 坑位清单

| 坑 | 对策 |
|---|---|
| A 中途提问也算 idle → B 提前触发 | A 提示词写"自主完成，不要中途提问"；或改用 §5 精确标记完成 |
| 权限模式不同 → 通知只展示不投递 | 用不带 message 的纯订阅；或两边统一权限模式 |
| B 关窗口 → 订阅消失 | B 挂 tmux |
| 拿不准哪个会话是目标 | ListAgents 看 cwd / tmux 位置对账 |
| A 是多回合长任务 | 每回合结束都算 idle；会中途停的任务用 §5 |

## 操作注意

- 给 B 的指令模板里务必写全任务 B 的描述 —— B 被唤醒时只靠那段预写指令行动
- 禁止轮询 ListAgents 等"are you done"（do not poll）；订阅本身就是轮询的替代品
- 给 busy 的会话发消息是安全的：入队不丢失
