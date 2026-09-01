---
name: init-repo
description: Clone a GitHub repo into /nfs/gogongxt/Projects (skip if exists), generate CLAUDE.md, run codegraph init, and summarize what the repo does. Trigger on "init repo", "拉取仓库", "clone 并分析仓库", or when user gives a repo URL and wants it set up and explained.
---

# init-repo

把用户指定的 GitHub 仓库拉取到本地、初始化索引并讲解仓库用途。

## 输入

用户会提供一个仓库地址或名字，如 `https://github.com/org/repo` 或 `org/repo`。

## 步骤

### 1. 获取仓库（如已存在则跳过）

- 目标目录：`/nfs/gogongxt/Projects/<repo-name>`
- 如果目录已存在且有 `.git`，直接跳过 clone，进入下一步
- 优先用 `/proxy` SKILL 开启代理，再在 `/nfs/gogongxt/Projects` 下执行 `git clone <url>`（统一用 https 地址）——国内直连 GitHub 很慢，优先走代理
- clone 失败可关闭代理直连重试一次；仍失败则停止并报告用户

### 2. 拉取成功后，以下三件事可以并行做

1. **生成 CLAUDE.md**：在仓库内基于代码结构生成（可参考 /init 的做法）
2. **codegraph init**：在仓库根目录执行，按下面的重试规则执行；仍失败就跳过并告知用户

#### codegraph init 重试规则

- 失败后 **不要删除已有的 `.codegraph/`**，保留现场，等待 10 秒后原样重试
- 最多重试 3 次（每次失败后等 10 秒）
- 重试期间不做其他破坏性操作（不 `rm -rf .codegraph`）
- 报 `database disk image is malformed` 时也一样先按上述规则重试（可能是竞争）
- 3 次重试全部失败、且报疑似磁盘/NFS 问题（如 `database disk image is malformed`、I/O error）时，走 /tmp 变通方案：
  1. 把仓库拷贝到 `/tmp/<repo-name>`，**排除已有的 `.codegraph/`**（损坏的索引不带走）
  2. 在 `/tmp/<repo-name>` 里执行 `codegraph init`
  3. init 成功后，用 `/tmp/<repo-name>/.codegraph/` 替换原仓库里损坏的 `.codegraph/`（此时才允许覆盖）
  4. 在**原仓库**里用 `codegraph explore "<symbol>"` 验证索引可读（在 /tmp 里能查不算数）
  5. 结束后清理 `/tmp/<repo-name>` 副本；变通方案也失败则放弃 init 并告知用户
- init 跑通后，用 `codegraph explore "<symbol>"` 验证索引可读
3. **阅读代码**：了解仓库结构、主要模块、入口，搞清楚这个仓库是做什么的

### 3. 汇报结果

最后给用户一个总结：
- 仓库是否新拉取 / 已存在跳过
- CLAUDE.md 是否生成
- codegraph 是否初始化成功
- 仓库是做什么的（简要架构 + 核心功能说明）

## 注意

- 遇到问题不要强行反复尝试或大量搜索，直接停止并把情况报告给用户
- 整体保持简单，不要做用户没要求的事
