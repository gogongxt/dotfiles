# Claude Code TODO / 追踪清单

> 更新于：2026-10-13
> **当前 Claude Code 版本：2.1.294**（记录时）
> 目的：把正在跟进、尚未落地的 Claude Code 需求集中记录，每个问题一个章节，包含「我的需求 / 当前机制 / 最新进展 / 相关 issue / 怎么复查」。
> 状态图：🔴 未解决 ｜ 🟡 有结论待落地 ｜ 🟢 已解决。
>
> **一个月后再看**：对每章直接跑「复查命令」那节，就能知道是否已有官方修复。所有 issue 都用 `gh`+代理查询（见文末速查）。

## 概览

1. 🔴 **`Ctrl+O` → `v` 打开对话历史，换行被终端宽度焊死** — 官方硬换行 long-standing，无开关，跟踪多为 open
2. 🟡 **`/copy`在 SSH+tmux+OSC52 下乱码 / 复制坏** — 有 META 跟踪，涉及 20+ open issue
3. 🔴 **`/init` 只写 CLAUDE.md，不能默认生成 AGENTS.md** — 无配置项，#97004 诉求中
4. 🔴 **显式提及 skill（如 `123 ... /proxy`）必须被读取** — 官方行为是"模型"，无强制读
5. 🔴 **statusline 上下文经 API 错误后假 0（synthetic 消息）** — #101314 未修；已有本地 workaround（见 §5）

---

## 1. 🔴 打开对话历史（Ctrl+O → v）换行被焊死

**需求**：在 transcript viewer 里按 `v` 用 `$EDITOR` 打开对话历史时，想要**原始逻辑换行**，而不是被终端宽度切好的“视觉换行”`\n`。

**现状（为什么不行）**：Claude Code 的 TUI 按终端宽度把长行**硬插入 `\n`**（word-wrap at boundaries），而不是发长逻辑行、让终端 soft-wrap。`v` 只负责把对话写入 `$VISUAL`/`$EDITOR`，本身不重排；所以编辑器里看到的就是渲染时已焊死的换行。

**最新进展（截至 2026-10）**：
- 官方**尚未实现** no-wrap / soft-wrap / `outputWrapping:"soft"` 配置项；CHANGELOG 里无相关词条。
- 目前可靠替代：非交互 `claude -p` 输出**不会**硬换行（已验证），可用它导出干净逻辑行。
- 社区 workaround（CLAUDE.md 加 "Do not use hard line breaks..." 指令）**不可靠**——常见长会话模型会忘记。

**相关 issue（均为 anthropics/claude-code）**：
| # | 状态 | 主题 |
|---|---|---|
| **#43113** | 🔴 open | 请求 `--no-word-wrap` / `CLAUDE_NO_WRAP=1` / `outputWrapping:"soft"` — **最新活跃跟踪点** |
| #13378 | 🔴 open | 2-space indent and hard wrap at 80 breaks copy-paste |
| #42296 | ⚫ closed（自动关，未修） | hard newlines for word wrap, breaking tmux copy mode（母 issue） |
| #35905 | ⚫ closed | Text output uses hard newlines instead of terminal soft-wrap |
| #8276 | ⚫ closed | Text doesn't reflow when terminal is resized |
| #24224 | ⚫ closed | Config option to control text wrapping（`outputWrapping:"soft"` 提出地，未实现） |
| #44741 | ⚫ closed | Claude Code hard-wraps text output |

**复查命令**：
```bash
grep -n -i "outputWrapping\|no-wrap\|soft-wrap\|CLAUDE_NO_WRAP" ~/.claude/cache/changelog.md
```

---

## 2. 🟡 `/copy`（及选择复制）在 SSH + tmux + OSC52 下乱码 / 复制坏

**需求**：在 SSH 登录后的 tmux 会话里用 `/copy` 或鼠标选择复制对话内容时，得到的文本**乱码 / 换行错乱 / 复制不进剪贴板**，希望恢复正常复制。

**现状**：根因是多层：
- Claude Code TUI 的复制管道在 OS/SSH/tmux 间的选择不可靠，常见问题是 **OSC52 直写不可靠、错误回退到 raw OSC52**，或 TMUX 环境变量不继承造成回退到 `native`/`osc52`。
- 硬换行（见 §1）也污染复制文本。
- 这是 **META #81472 已跟踪的系统性缺陷**（当前已列 42 个 open issue，覆盖 TUI/VS Code/Desktop）。

**相关 issue**：
| # | 状态 | 主题 |
|---|---|---|
| **#81472** | 🔴 open | [META] Copy/paste broken across all surfaces — **跟踪所有 copy/paste 问题** |
| **#88772** | 🔴 open | SSH+tmux 下 OSC52 回退不可靠；detail view 里 TMUX 环境变量丢失 → raw OSC52 |
| **#86290** | 🔴 open | 后台 agent 会话复制坏了：daemon 起 bg-pty-host 时 `TMUX` 被剥离 |
| #48037 | 🔴 open | Copying text includes hard line breaks at every wrapped line（linked to §1） |
| #18170 | 🔴 open | Copy/paste includes unwanted indentation / trailing spaces |

**复查命令**：
```bash
gh api "search/issues?q=repo:anthropics/claude-code copy paste OSC52" --jq '.items[] | "#\(.number) [\(.state)] \(.title)"' | head -20
```

---

## 3. 🔴 `/init` 默认生成 CLAUDE.md，不能改为 AGENTS.md

**需求**：希望 Claude Code 在 `/init` 时**默认生成 `AGENTS.md`**（与社区其他 coding agent 统一），而不是 `CLAUDE.md`。

**现状**：
- `/init` **始终写 `CLAUDE.md`**，无设置项 / env / flag 可让其输出 `AGENTS.md`（官方 memory 文档 + CLI 参考均只提 CLAUDE.md）。
- v2.1.277 起 Claude Code **能读** `AGENTS.md`，但仅在**无 `CLAUDE.md` 时**才读；两者都有则只读 `CLAUDE.md`（除非 Project instructions 设为 `claude-md-and-agents-md`）。
- **正是因为你想要 AGENTS，若 `/init` 生成了 CLAUDE.md，反而会让 AGENTS.md 失效** —— 这是一处已知缺陷。

**相关 issue**：
| # | 状态 | 主题 |
|---|---|---|
| **#97004** | 🔴 open | `/init` writes CLAUDE.md in an AGENTS.md project, **silently disabling the instructions it just read**（最贴近需求） |
| #96466 | 🔴 open | Always load AGENTS.md by default, make CLAUDE.md optional |
| #34235 | 🔴 open | Feature request: support AGENTS.md as native context file alongside CLAUDE.md |
| #41172 | ⚫ closed | `/init` skill doesn't discover AGENTS.md |

**复查命令**：看 #97004 是否被 assign/修复；CHANGELOG 搜 `NEW_INIT` / `/init` 是否新增「write AGENTS.md」选项。
```bash
grep -n -i "CLAUDE_CODE_NEW_INIT\|AGENTS\.md" ~/.claude/cache/changelog.md | head
```

---

## 4. 🔴 skill 显式提及（`123 ... /proxy`）必须被读取

**需求**：在新版 Claude Code 中，skill 是否加载**由模型自主判断**；但用户希望：**只要消息里显式写了 skill 名（即使不是行首、如 `123 ... /proxy`），Claude 就**必须**读取/调用该 skill**。

**现状（为什么模型会跳过）**：官方 skills 文档：
> 中段的斜杠引用（如 `go ahead and /proxy`）**不会直接运行**，只算“本条消息的授权”，由 Claude 从措辞判断是否真要调用；不写斜杠则**不授权**。
> `description`/`when_to_use` 由模型自行判断；`disable-model-invocation:true` 时连描述都不进上下文。

所以「显式提到但没读」正是新机制（模型自行判断）的结果，并非 bug；要“必须读”还缺一个强制手段。

**workaround（对你要强读的语气）**：
- 把 `/proxy`（或 skill 名）放在**行首**、并让其在 picker 里成为蓝色“芯片”→ CLI 直接执行，绕开模型判断。
- 或用 `@skillname`（@-mention 形式）→ 在某些渲染器下可稳定 attach。

**相关 issue**：
| # | 状态 | 主题 |
|---|---|---|
| **#94564** | 🔴 open | Invoked skill not re-attached after /compact（技能上下文会丢） |
| #94309 | 🔴 open | Cowork：中段手打斜杠只有被 picker 解析成蓝色芯片才执行，否则变纯文本 |
| #89398 | 🔴 open | Slash picker 只在 `/` 是首字符时打开 |
| #91094 | 🔴 open | Desktop：中段 /skill 自动补全失效 |

**复查命令**：
```bash
grep -n -i "skill.*invoc\|model.*skill\|disable-model-invoc" ~/.claude/cache/changelog.md | head -20
gh api "search/issues?q=repo:anthropics/claude-code skill explicit invoke" --jq '.items[] | select(.state=="open") | "#\(.number) \(.title)"'
```

---

## 5. 🔴 statusline 上下文经 API 错误后假 0（synthetic 消息）

**需求**：statusline 的上下文（`30.3k/1000k`）在运行过程中**有时突然变成 `0/1000k`**，且一直持续到下一次真正成功的回复。希望显示的是"最近一次真实读数"，而不是假 0。

**根因（官方 bug，非脚本问题）**：某轮请求以 API 错误结束（如 `Can't reach the API server … ENOTFOUND`）或出现 `No response requested.` 时，Claude Code 会给 transcript 追加一条 **synthetic assistant 消息**（`"model": "<synthetic>"`），其 `usage`（input/cache_read/cache_creation）**全部为 0**。statusLine payload 的 `context_window.used_percentage` / `total_input_tokens` 取自「最后一条带 usage 的 assistant 消息」，于是变 0，且直到成功回复前不恢复。`/context` 不受影响。

**本地 workaround（已落地 2026-10-13）**：`~/.claude/scripts/statusline.sh` 增加 per-session 缓存兜底：
- 每个 session 一个文件 `$XDG_CACHE_HOME/claude-code/statusctx/ctx.<session>`，**只在非零 tick** 时原子更新（tmp+mv）。
- tick 判定为 0（`total_input_tokens == 0`）时，从缓存恢复**最近非零读数**（tokens/pct/total）。
- 全新会话首 tick（无缓存）或 `/clear` 后 → 真实 0 仍显示 0，不误报。compact 后低值（如 0.1%）非零 → 正确覆盖缓存。

**相关 issue**：
| # | 状态 | 主题 |
|---|---|---|
| **#101314** 🔴 open | statusLine `used_percentage` 在 API 错误后掉到 0（synthetic assistant 全零 usage）—— 官方修复点 |
| #62768/#58268 | closed(dup) | /compact 后 statusline 一次归零（如果 #101314 用「跳过 synthetic」修，这个也会被覆盖） |
| #18241 | open | statusline / /context / 内置警告百分比不一致（相关，非同一 bug） |

**复查命令**：看 #101314 是否被 assign/fix，或 CHANGELOG 是否加了「跳过一次 0 的 synthetic 条目」。
```bash
gh issue view 101314 -R anthropics/claude-code 2>&1 | head -20
grep -n -i "synthetic\|used_percentage" ~/.claude/cache/changelog.md
```

---

## 复查速查（一个月后用）

对所有章节，最省力方式：
1. 先跑 `grep -n -i "<关键词>" ~/.claude/cache/changelog.md` —— 本地 changelog 缓存，离线最快。
2. 再用 `gh api search/issues` 查对应 issue 是否被 assign / comment 数变化 / 状态翻转。
3. 若某章 issue 已被 fix，则可用以下 `agent` 帮助从 `claude --version` + `claude update` 确认当前版本是否包含。

> 相关 issue 都是在 `anthropics/claude-code` 上公开的；状态会随时间变化，复查时以当时搜到的为准。