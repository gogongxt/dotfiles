# Claude Code TODO / 追踪清单

> 更新于：2026-11-12（**新增 §8 slash 命令必须行首**；§1–§7 全部复查，结论见文末速览表；官方 CHANGELOG 仍到 2.1.322）
> **当前 Claude Code 版本：本机已升级到 2.1.322；官方最新 2.1.322**（自 11-10 起无新版本）
> 目的：把正在跟进、尚未落地的 Claude Code 需求集中记录，每个问题一个章节，包含「我的需求 / 当前机制 / 最新进展 / 相关 issue / 怎么复查」。
> 状态图：🔴 未解决 ｜ 🟡 有结论待落地 ｜ 🟢 已解决。
>
> **一个月后再看**：对每章直接跑「复查命令」那节，就能知道是否已有官方修复。所有 issue 都用 `gh`+代理查询（见文末速查）。

## 概览

1. 🔴 **`Ctrl+O` → `v` 打开对话历史，换行被终端宽度焊死** — 官方硬换行 long-standing，无开关；#43113 已标 `duplicate`，仍无 soft-wrap 实现
2. 🟡 **`/copy`在 SSH+tmux+OSC52 下乱码 / 复制坏** — META #81472 跟踪，仍 open（11-05）；**2.1.322 已含 2.1.176 的 tmux+SSH 修复，值得重测**
3. 🔴 **`/init` 只写 CLAUDE.md，不能默认生成 AGENTS.md** — 无配置项，#97004 仍 open
4. 🟡 **显式提及 skill（如 `123 ... /proxy`）必须被读取** — **2.1.287 已改进**（中段 skill 名会告知模型），非强制（见 §4）；2026-11-12 补：官方文档已把该语义写成设计，**mod 可用 `$.skill.prompt` 确定性注入正文**（绕过 Skill 工具，无工具授权），社区主流是路由提示（概率性）或 Stop 闸门（事后），见 §8「社区方案」
5. 🔴 **statusline 上下文经 API 错误后假 0（synthetic 消息）** — #101314 未修；已有本地 workaround（见 §5）
6. 🟡 **statusline 上下文某一刻翻倍/多倍后回弹（usage 按 iterations 求和）** — **2.1.273 已修 advisor 路径**；非 advisor 多迭代路径未证实修复；**2026-11-12 复查：官方到 2.1.322 仍未修复**，#84738 活动停在 11-01 的第三方审计（2.1.316 受控重放不复现，但未覆盖非 advisor 路径，详见 §6）；auto-compact 阈值语义已从 2.1.294 二进制解出（见 §6）
7. 🟡 **子 agent 指定别的模型（如 /code-review 换模型 review）** — 机制本身存在（frontmatter `model:` / Agent 工具 `model` 参数 / `CLAUDE_CODE_SUBAGENT_MODEL`），但 2.1.223+ 有静默丢弃回归（#85592）等一串不生效 bug（见 §7）
8. 🔴 **slash 命令必须写在行首才派发** — 命令放到句中/末尾只当普通文本，`command.run` hook 不触发（handoff 这类依赖 hook 的 mod 因此完全失效）；官方文档已把「中段 = 仅授权、模型自行判断」写成设计，无开关（见 §8）

---

## 1. 🔴 打开对话历史（Ctrl+O → v）换行被焊死

**需求**：在 transcript viewer 里按 `v` 用 `$EDITOR` 打开对话历史时，想要**原始逻辑换行**，而不是被终端宽度切好的“视觉换行”`\n`。

**现状（为什么不行）**：Claude Code 的 TUI 按终端宽度把长行**硬插入 `\n`**（word-wrap at boundaries），而不是发长逻辑行、让终端 soft-wrap。`v` 只负责把对话写入 `$VISUAL`/`$EDITOR`，本身不重排；所以编辑器里看到的就是渲染时已焊死的换行。

**最新进展（截至 2026-10-16）**：
- 官方**仍未实现** no-wrap / soft-wrap / `outputWrapping:"soft"` 配置项；已刷新到 2.1.301 的 CHANGELOG 里仍无相关词条（只搜到一处不相关的 AskUserQuestion preview word-wrap 修复）。
- 目前可靠替代：非交互 `claude -p` 输出**不会**硬换行（已验证），可用它导出干净逻辑行。
- 社区 workaround（CLAUDE.md 加 "Do not use hard line breaks..." 指令）**不可靠**——常见长会话模型会忘记。
- **#43113 已被官方打上 `duplicate` 标签**（另有 `enhancement`/`area:tui`），且有多条 cross-reference（#44741、#47652、#64995、#13378 等），但**未见指定哪个是主 issue** —— 复查时优先看这些 cross-ref 里哪个转「开放跟踪」。

**相关 issue（均为 anthropics/claude-code）**：
| # | 状态 | 主题 |
|---|---|---|
| **#43113** | 🔴 open（已标 `duplicate`） | 请求 `--no-word-wrap` / `CLAUDE_NO_WRAP=1` / `outputWrapping:"soft"` — 仍是最贴近诉求的跟踪点 |
| #13378 | 🔴 open（2026-10-10 有更新） | 2-space indent and hard wrap at 80 breaks copy-paste |
| #22073 | 🔴 open | Copy/paste from terminal has new lines instead of wrapping properly（**2026-10-16 仍活跃**） |
| #48037 | 🔴 open | Copying text from terminal output includes hard line breaks at every wrapped line |
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
- 这是 **META #81472 已跟踪的系统性缺陷**（当前已列 42 个 open issue，覆盖 TUI/VS Code/Desktop）。**2026-11-12 复查：仍 open（11-05，14 评论）**，但底层场景在零星修：2.1.176 修 `tmux over SSH` 下 `/copy` 和鼠标选择不进系统剪贴板、2.1.224 修 Wayland copy-on-select 竞态、2.1.275 修 `--resume` 选择器鼠标选中不进剪贴板。**本机 2.1.322 已含这些修复，§2 的症状值得重测一次**。

**相关 issue**：
| # | 状态 | 主题 |
|---|---|---|
| **#81472** | 🔴 open（2026-10-15 更新） | [META] Copy/paste broken across all surfaces — **跟踪所有 copy/paste 问题** |
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
- **（2026-10-16 复查）** 仍无 `/init` 生成 AGENTS.md 的开关；相关 bug 有新增但都是旁支：**#96117**（`CLAUDE.local.md` 会关掉 AGENTS.md 回退，一处个人笔记静默丢弃全部共享项目指令）、**#99275**（EnterWorktree 不加载 worktree 根的 CLAUDE.md/@imports）。
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

## 4. 🟡 skill 显式提及（`123 ... /proxy`）必须被读取

**需求**：在新版 Claude Code 中，skill 是否加载**由模型自主判断**；但用户希望：**只要消息里显式写了 skill 名（即使不是行首、如 `123 ... /proxy`），Claude 就**必须**读取/调用该 skill**。

**现状（为什么模型会跳过）**：官方 skills 文档：
> 中段的斜杠引用（如 `go ahead and /proxy`）**不会直接运行**，只算“本条消息的授权”，由 Claude 从措辞判断是否真要调用；不写斜杠则**不授权**。
> `description`/`when_to_use` 由模型自行判断；`disable-model-invocation:true` 时连描述都不进上下文。

所以「显式提到但没读」正是新机制（模型自行判断）的结果，并非 bug；要“必须读”还缺一个强制手段。

**最新进展（截至 2026-11-12，在 2026-10-16 基础上补）**：
- **官方定性已确认**：docs/skills 的 “Where you write the skill's name” 把「行首 = 直接执行 / 中段 = 仅授权、模型自行判断」写成正式语义，不是 bug、无开关。见 §8。
- **"必须读" 的确定性做法已找到（mod 层）**：`$.session.usage({breakdown:'summary'})` 拿 skill 列表 + `$.skill.prompt({skill})` 取正文 → 注入 `prompt.submit` 的 `context`。不经过模型判断；代价是绕过 Skill 工具（无 `allowed-tools` 授权、不计入 `invoked_skills`、compact 后不 re-attach）。社区暂无实现，因为该 API 只有 mod 能用。见 §8 社区方案第 2 类。
- **社区主流仍是概率性方案**：路由注入（claude-capability-router / vstack / toolkit-router）或 Stop 闸门（vstack `skill-mandate.sh`，事后纠错）。见 §8。
- **v2.1.287（2026-10-01）已改进中段 skill 名识别**：CHANGELOG 原文「Improved `/skill` names typed mid-message: Claude is now told they are skills, including `disable-model-invocation` ones」——即中段打出的 skill 名现在**会被明确标注为 skill 并告知模型**（含 `disable-model-invocation` 的）。这比之前「纯靠措辞猜」前进了一步，但**仍是告知模型、由模型判断，不是强制调用**。
- 早前相关：v2.1.199 支持 `skill-a /skill-b do XYZ` 堆叠时加载前 5 个前导 skill；v2.1.110 修过中段 `/<skill>` 的 `disable-model-invocation` 报错；v2.1.222 改进 `disable-model-invocation` 的拒答措辞（改为请用户自己跑）。
- 结论：**诉求（强制读）仍无官方开关**，但中段提及已被官方承认并半修复；若你要“必读”，行首芯片 / `@skillname` 仍是最稳路径。

**workaround（对你要强读的语气）**：
- 把 `/proxy`（或 skill 名）放在**行首**、并让其在 picker 里成为蓝色“芯片”→ CLI 直接执行，绕开模型判断。
- 或用 `@skillname`（@-mention 形式）→ 在某些渲染器下可稳定 attach。

**相关 issue**：
| # | 状态 | 主题 |
|---|---|---|
| **#94564** | 🔴 open（2026-11-06 有 2.1.319 复现） | Invoked skill not re-attached after /compact（技能上下文会丢） |
| #94309 | 🔴 open | Cowork：中段手打斜杠只有被 picker 解析成蓝色芯片才执行，否则变纯文本 |
| #93252 | 🔴 open（11-01，0 评论） | Hooks 能注入文本但**不能 load 一个 skill**；`additionalContext` 10k 上限、不计入 `/context`、compact 后不 reload —— 「强制读」缺的正是这个能力（见 §8） |
| #104643 | 🔴 open（10-23） | 任意位置 typeahead + 一条消息加载所有点名 skill（enhancement，明写 mod 只能 approximate） |
| #89398 | 🔴 open | Slash picker 只在 `/` 是首字符时打开 |
| #91094 | 🔴 open | Desktop：中段 /skill 自动补全失效 |

> 注：#94564 已从「compact 后丢技能」收窄为**根因**——被调用 skill 的注册表存在**进程内存**里，`--resume` 时只从 `invoked_skills` attachment 重建，不读调用记录，所以**跨进程恢复**就会丢（2.1.301 仍复现，2026-10-16 有最小复现 + 源码定位）。**2026-11-12 复查：2.1.319 上仍复现**（YevheniiKotyrlo 11-06 贴了免登录的 node 复现脚本），官方无动作。与「中段提及」是不同子问题。
>
> 但同方向有一个真正的修复：**2.1.304 起 compaction 之后会重新把 skill 列表发给模型**（CHANGELOG：「Changed compaction to send Claude the skill list again afterwards; `/reload-skills` now sends only new or changed skills」）。这修的是「compact 后模型不知道自己有哪些 skill」，**不是**「已调用 skill 的正文没有 re-attach」——两者别混。

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

**（2026-10-16 复查）**：#101314 仍 **open、无 assign、无评论**，标签 `bug`/`has repro`/`area:statusline`，最后更新 2026-10-11。已刷新到 2.1.301 的 CHANGELOG 里**无 synthetic/statusline 相关修复**（只搜到一处 print/SDK 模式的 synthetic tool denial，无关）。→ **本地 workaround 仍需保留。**

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

## 6. 🟡 statusline 上下文某一刻翻倍/多倍后回弹（usage 按 iterations 求和）

**需求**：statusline 的上下文（如 `135k/1000k`）在运行中**某一刻突然变成约 2 倍**（`270k/1000k`），**下一拍又掉回原值**。希望显示的始终是「最近一次真实上下文占用」。

**根因（官方 bug，非脚本问题）**：单个 assistant turn 可能包含**多次 API iteration**（工具调用后继续、重试、`advisor()` 调用等）。CC 把该 turn 的 **top-level `usage` 记为所有 `usage.iterations` 的求和**，而 statusLine 的 `context_window.used_percentage` / `total_input_tokens` 正是取自这条 top-level usage。于是：

> **一个 turn 有 N 次迭代 ⇒ 同一份上下文被计数 N 次 ⇒ 显示值放大 N 倍。**

**放大倍率 = 该 turn 里 `type:"message"` 迭代的条数**（不是固定 ×2）。下一拍是单迭代 turn，值立刻回落到真实值。**纯显示假象**：prompt cache 与执行器真实上下文完全没动。

与 §5 假 0 的关键区别：
- §5 有**明确判定信号**（`total_input_tokens == 0`）→ 能可靠做本地兜底。
- §6 **没有可靠信号**：一拍 270k 无法判断「是真涨了」还是「135k 被翻倍」。唯一 heuristic 是「限制单拍涨幅不超过 ~1.8×」，但会误杀真实的大跳变（如读入大文件），**不值得做**。→ 只能等官方修。

**混淆点：这不是 `advisor()` 专属**。我（网关自建，无 advisor）同样会触发。`advisor()` 只是最显眼的复现路径；**任意多迭代 turn**（普通工具续跑、缓存 miss 重试）都会翻倍。修 `advisor` 一个点并不能覆盖此路径。

**最新进展（截至 2026-10-16）**：
- ✅ **v2.1.273（2026-09-15）已发官方修复**，CHANGELOG 原文：「Fixed the context meter and auto-compact counting advisor-tool turns at roughly twice their real context size, which made auto-compact fire at about half the real window」。→ **§6 的 advisor 路径（#53065 类）在 2.1.273 起应已修复**。
- ⚠️ **但修复面较窄**：#84738（2.1.227/2.1.228 复现）指出**非 advisor 的多迭代 turn**（普通工具续跑、缓存 miss 重试）同样放大 —— 官方词条只提「advisor-tool turns」。**这些普通路径是否被同一修复覆盖，尚未证实**；这也正是我（网关自建、无 advisor）命中 §6 的关键。下次复发时需读 transcript 确认是否 advisor。
- 修复用的「取最终 iteration」helper 其实早在 2.1.260 的 bundle 里就存在（用于 compaction 记账），但**直到 2.1.273 才接到 context meter / auto-compact 触发上**。参见 #84738 的源码级分析（`mFe` 读 top-level 求和 vs `Cta` 取 `iterations.at(-1)`）。
- **非近期回归**：6,210 个 session 文件里**没有任何一个正确上报的多迭代 turn**，最早的（2.1.181）已是 1.979×。
- **附带影响**：同一份被放大的 usage 也喂给 auto-compact 阈值（同时喂 token 上限与百分比/auto 两种触发，换触发方式无济于事）→ 真实上下文远未满即提前压缩。#84738 侧记：「saved N tokens」提示也会继承放大值（报 904.2k，实际约一半）。
- **前情（修复前状态）**：2.1.227（desktop bundled）/ 2.1.228（CLI）仍复现；A/B 实测真实 411K 时以报告的 823K 触发压缩，411K 被压到 7,161 tokens。

**2026-10-26 专项复查（当时官方 2.1.310、本机 2.1.294；下文阈值/取证结论均基于 2.1.294 基线）**：
- **#84738 仍 open**（`area:core`，2 条评论），**2026-09-08 后零活动** —— 2.1.273 之后官方没再动过这个 issue。
- 官方 CHANGELOG 刷至 **2.1.310**：2.1.273 之后**没有任何新的 rollup / context-meter 修复词条**。只有旁支：**2.1.304** 修 `CLAUDE_CODE_AUTO_COMPACT_WINDOW=200k` 被静默当 100K（现在支持 `k`/`M` 后缀、越界会告警）；**2.1.300** 修选小窗口时 `/autocompact` 的高占用误告警；**2.1.288** 修「最后一拍 usage 为 0 时不压缩直接报 Prompt is too long」+ 首个请求改用服务端上报的窗口/输出上限；**2.1.285** 自定义 `ANTHROPIC_BASE_URL` 的会话改用模型真实窗口（网关只有 200K 时需 `/autocompact 200k`）。→ **非 advisor 多迭代路径仍未证实修复**。
- **取证方法变更（重要）**：2.1.294 起 transcript 的 `usage.iterations` **已不再落盘**（本机某会话 3,758 条 assistant 行全为空数组），旧的「sum(iterations) vs 最后一条」检测法失效。新方法：扫 top-level usage 的 **V 型反转**（见下方自查脚本）。
- **本机 2.1.294 期间未复发**：近 21 天 V 型扫描 0 命中；期间 4 次 auto-compact 全部是 usage 平滑爬升到 ~303k 诚实触发（当时 env 窗口还是 1M，模型窗口 ~400k → 0.8×(400k−20k)=304k，精确吻合）。**（该「0 命中」记录属 2.1.294 基线；本机 2026-10-30 已升到 2.1.314。）**
- **auto-compact 阈值语义（从 2.1.294 二进制解出）**：env `CLAUDE_CODE_AUTO_COMPACT_WINDOW` 优先级最高，**实际窗口 = min(模型上下文窗口（网关上报）, env 值)**；可用窗口 = 窗口 − min(maxOutputTokens, 20k)；**触发阈值 ≈ 0.8 × 可用窗口**（比例来自服务端 statsig 按窗口大小下发，非固定常量）；`CLAUDE_CODE_BLOCKING_LIMIT_OVERRIDE` 是更外层的 blocked 线（本机设 1048576）。⚠️ 所以 `358400` 的实际效果是**约 270.7k 就压缩，不是 350k**。
- **注意调大窗口治标不治本**：触发线随窗口缩放，真实占用 ≥ 触发线一半时，一次 ×2 仍会越线 —— 根治只能等 #84738。

**2026-10-30 复查（官方已到 2.1.314；本机同日已升级到 2.1.314）**：
- **仍未修复**。#84738 仍 open（`area:core`，2 条评论，无 assignee），**updated_at 停在 2026-09-08**，2.1.273 后官方零活动；#53065 仍 open（18 评论，停在 2026-09-24）。
- CHANGELOG 自 2.1.310 后新增 **2.1.311 / 2.1.312 / 2.1.314**（无 313）：无任何 context meter / iteration rollup / usage 翻倍修复词条。旁支相关：2.1.312 改子代理 `autoCompactWindow` 只降不升 `CLAUDE_CODE_AUTO_COMPACT_WINDOW` 的窗口；2.1.311 修 200K+ 会话报 "Usage credits required for 1M context" 时改为压缩后继续、修 `/usage` 不显示大额 prompt-cache miss。均与 §6 无关。
- **升级侧的间接影响（待观察）**：2.1.304 起 `CLAUDE_CODE_AUTO_COMPACT_WINDOW` **支持 `k`/`M` 后缀**、越界会告警（本机用的是纯数字 `358400`，两版都可用）；2.1.301 修了「LLM 网关返回模型名与请求不一致时会话被反复压缩」——这条仍属**压缩触发**旁支，可能有助缓解「真实未满却提前压缩」的观感，但**不是** §6 的 usage 翻倍修复。2.1.300 起 `/advisor` 也上了 Claude Platform on AWS，注意别误开 advisor 路径（2.1.273 只修了 advisor 路径，非 advisor 多迭代路径仍无修复）。
- **本机已完成升级，故 V 型扫描的基线版本变了**：此前 21 天「0 命中」是 2.1.294 上的记录；下次复发取证要在 **2.1.314** 上重跑（`usage.iterations` 自 2.1.294 起已不落盘，仍用 V 型反转扫描）。
**2026-11-10 复查（官方已到 2.1.322；本机仍 2.1.314）**：
- **仍未有官方修复词条**。2.1.314 之后新增 316/317/318/319/321/322（无 315/320），grep 全部换行/iteration/rollup/context meter 关键词，唯一沾边的是 **2.1.321「Fixed context usage estimates overcounting tool definitions when exact token counts are unavailable」** —— 修的是**估算路径多算工具定义**，与 top-level usage 按 iterations 求和无关，不算 §6 修复。
- **#84738 仍 open，但有 2026-11-01 新评论（@CBEPX，第三方审计）**：复扫 6,443 行 transcript，确认 92 个放大样本全是「两次 message iteration + 一次 advisor」结构；并在 **2.1.316 上做了两组受控 Read/tool 重放，4 条 final message 满足 nested-sum 不变量（不再复现）**。但评论明确声明：控制组不证明历史 advisor 案例已修、未测压缩阈值、更不涉及非 advisor 多迭代路径 → **对我（无 advisor 网关）的路径仍无结论**。
- 其余 issue 状态：#53065 仍 open（18 评论，停在 09-24）；§1–§5 的 #43113/#81472（11-05 活跃）/#97004/#101314/#94564（11-06 活跃）均 open 无官方动作。
- **下次复查动作不变**：若 statusline 再拍到 ×2，在 2.1.314（或升级后版本）跑 §6 的 V 型扫描 + `advisor_message` 计数取证。

**相关 issue（均为 anthropics/claude-code）**：
| # | 状态 | 主题 |
|---|---|---|
| **#84738** | 🔴 open（2026-11-10 复查：11-01 有第三方审计评论，2.1.316 受控重放不复现） | Advisor turns roll up usage summed across iterations… —— **当前活跃跟踪点**，transcript 级证据最全 |
| **#53065** | 🔴 open c=18（停在 2026-09-24） | `advisor()` inflates reported input tokens…触发过早 auto-compact（**2.1.273 应已修此路径**） |
| #61511 | ⚫ closed（auto，未修） | Context meter ~doubles during in-flight advisor call, reverts on cancel |
| #81620 / #81029 | ⚫ closed | advisor 翻倍 / 触发 spurious compaction（dup） |
| #18241 | 🔴 open | statusline / /context / 内置警告百分比不一致（相关，非同一 bug） |
| #49927 / #18781 | ⚫ closed | statusline 闪烁/归零相关，**机制不同**（非本节） |

**关键数据（#84738，最新最全）**：
- 1,731 个多迭代 turn：×2（1,218 个）、×3（219）、×4（191）、×5（74）、×6（29）；**最差 5.14×**（真实 25,004 报成 128,519）。
- **96 个被放大的 turn 完全不含 `advisor_message`** —— 普通工具续跑即触发。

**复查命令**：advisor 路径已于 2.1.273 修。现在要复查的是**非 advisor 多迭代路径**是否也修了 —— 在你自己会话里抓一次放大 turn，读 transcript 确认它**不含 advisor** 却仍被放大，即可判定修复不全、issue 仍需跟。
```bash
gh issue view 84738 -R anthropics/claude-code 2>&1 | tail -40   # 看是否有 2.1.273 之后的确认/关闭
gh issue view 53065 -R anthropics/claude-code 2>&1 | head -20
# changelog 缓存可能过期，直接从官方刷新再 grep：
curl -sL https://code.claude.com/docs/en/changelog.md -o /tmp/cc-cl.md && \
  grep -n -i "context meter\|iteration\|roll.up\|summed\|auto-compact counting" /tmp/cc-cl.md
```

**如何自查是否命中**（**2026-10-26 更新**：2.1.294 起 `usage.iterations` 已不落盘，旧 grep 法失效，改用 V 型反转扫描）：
```bash
# 扫 top-level usage 的 V 型反转：本拍 ≥1.7× 前拍、下一拍 ≤0.65× 本拍、中间无 compact 边界
python3 - ~/.claude/projects/<proj>/<session>.jsonl <<'EOF'
import json, sys
U = lambda o: (o.get("message") or {}).get("usage") or {}
T = lambda u: u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0) + u.get("cache_creation_input_tokens", 0)
L = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
A = [i for i, o in enumerate(L) if o.get("type") == "assistant" and T(U(o)) > 0]
for k in range(1, len(A) - 1):
    p, c, n = (T(U(L[j])) for j in (A[k-1], A[k], A[k+1]))
    if p > 20000 and c >= 1.7 * p and n <= 0.65 * c and n >= 0.5 * p \
       and not any(L[j].get("isCompactSummary") for j in range(A[k], A[k+1])):
        print("SPIKE", L[A[k]].get("timestamp", "?")[:19], f"{p//1024}k -> {c//1024}k -> {n//1024}k")
EOF
# 命中后分辨路径：grep -c advisor_message <session>.jsonl（>0 → advisor 路径，2.1.273 应已修；=0 → 非 advisor 路径，未证实修复）
```
> ⚠️ 盲区：若 spike 后**紧跟 compact**（无回落拍可检），V 扫不命中——此时看 compact 边界前最后一拍是否 ≥1.6× 再前一拍（本机 10-14~16 的 4 次压缩全是平滑爬升，非此类）。
> ⚠️ 会话内更省事：statusline 拍到一次 ×2 后立刻跑上面脚本；命中 SPIKE 且 advisor_message=0 即可给 #84738 添证据。

---

## 7. 🟡 子 agent 指定别的模型（如 `/code-review` 换模型 review）

**需求**：主会话用一个模型，启动子 agent（尤其 `/code-review` 这类 skill 触发的 reviewer 子 agent）时换成别的模型（更便宜/更快/更专注审查的模型）。

**当前机制（三层，理论上都支持）**：
1. **Agent 定义 frontmatter**：`.claude/agents/<name>.md` 头部写 `model: haiku`（或 `sonnet`/`opus`/完整 model id）→ 该 agent 恒定用指定模型。
2. **Agent 工具调用参数**：`Agent` 工具有 `model` 参数，可每次调用时覆盖（本会话系统提示里也写明「Optional model override … Takes precedence over the agent definition's model frontmatter」）。
3. **环境变量 `CLAUDE_CODE_SUBAGENT_MODEL`**：settings.json `env` 里设，所有子 agent 默认走指定模型。
4. （旁支）**`CLAUDE_CODE_SUBAGENT_EFFORT`**：2.1.316 新增，控制子 agent 的 effort（不继承 session 的）——只控 effort 不控模型。

**但社区大量 issue 集中在「机制存在却不生效」**：最关键的是 **#85592**——自 v2.1.223 起，设了 `CLAUDE_CODE_SUBAGENT_MODEL` 后**显式 per-call / frontmatter 模型会被静默丢弃**（回归窗口已定位 2.1.220→223），且子 agent `.meta.json` 记的是请求模型而非实际模型。2.1.314 上的行为需要自验。

**相关 issue（均为 anthropics/claude-code）**：
| # | 状态 | 主题 |
|---|---|---|
| **#85592** | 🔴 open（回归窗口 2.1.220→223 已定位，无官方回应） | `CLAUDE_CODE_SUBAGENT_MODEL` 静默丢弃显式 per-call 子 agent 模型 —— **最强跟踪点** |
| #100082 | 🔴 open | 1,371 个子 agent 里 1,149 个忽略 frontmatter `model:`（10-06 报） |
| #92290 / #92715 | 🔴 open | 子 agent 不 respect 显式模型 / `CLAUDE_CODE_SUBAGENT_MODEL` 继承问题 |
| #106383 | 🔴 open | model picker 换模型不应用到显式指定模型的子 agent |
| #103733 | 🔴 open | 请求把「实际解析的模型+定义来源」放进 Agent PreToolUse 输入（可观测性） |
| #102655 / #104691 | 🔴 open | 无法看到/确认子 agent 实际跑的模型 |
| #93157 | 🔴 open | opusplan 模式覆盖子 agent frontmatter 模型 |
| #106208 | 🔴 open | 恢复的子 agent 静默继承父模型（丢原定义） |

**相关 CHANGELOG 动向**：
- 2.1.316：新增 `CLAUDE_CODE_SUBAGENT_EFFORT`。
- 2.1.317：「subagents/teammates on a different model 用该模型自己的 saved effort 或默认值，不再用 session 的 effort」——官方在收敛子 agent 模型/effort 语义。
- 2.1.318：「Switch models when a message is flagged → Ask each time」时子 agent 改为 stop 而不是换模型。
- 2.1.316 修复：「继承了父 subagent 模型的 sub-agents 在被后台任务唤醒时错误地切回主模型」。

**实操（今天 2.1.314 可用）**：
- 给 review 场景建 `~/.claude/agents/code-reviewer.md`（带 `model:` frontmatter），或全局设 `CLAUDE_CODE_SUBAGENT_MODEL`。
- ⚠️ 因 #85592/#100082，**设置后必须验证生效**：让 reviewer 回报自己的 model id，或看 #103733 请求的 PreToolUse 可观测性（尚未实现）。
- `/code-review` 是 skill，内部起的 reviewer 子 agent 同样走这套机制 → 同样受上述 bug 影响。

**复查命令**：
```bash
gh issue view 85592 -R anthropics/claude-code --comments 2>&1 | tail -30   # 看回归是否被官方确认/修复
grep -n -i "subagent.*model\|SUBAGENT_MODEL" /tmp/cc-cl.md   # changelog 里查子 agent 模型相关修复
gh api "search/issues?q=repo:anthropics/claude-code+subagent+model+in:title&per_page=20" --jq '.items[] | "#\(.number) [\(.state)] \(.title[:80])"'
```

---

## 8. 🔴 slash 命令必须写在行首才派发（句中/末尾静默失效）

**需求**：`/handoff`、`/proxy` 这类命令，不管写在一句话的开头、中间还是末尾，都应该被识别并触发对应的 hook / skill。实际想要的是一个「位置无关」的识别。

**现状（为什么不行）**：Claude Code 只把**消息开头的第一个 token**（trim 后）当命令名解析，后面跟空格的才是参数。命令出现在句中或末尾时**完全不进命令解析**，不会注入 `<command-name>`，`command.run` hook 不触发，模型收到的就是一段普通文本。**静默失败**：没有报错、没有警告、输入框里甚至照样高亮。

对本人的实际影响（2026-11-12 实测）：
- `/handoff` 写在句尾 → 模型会“理解”你要干什么，甚至会自己解释“这是内置命令我调不了”，但 **hook 不跑 → 不会 compact → 不走 resume 流程**，等于功能全失效。mod 里的动作（compact/resume）全在 hook 手里，模型没有权限自己调 `$.session.compact`。
- 对照实验（headless `claude -p`）：`简单介绍下…，最后再用 /handoff 收尾` → 未触发；`/handoff 简单介绍下自己` → 立刻返回 `Handoff: writing /tmp/…, then compacting and resuming.`

**官方定性（重要，不是 bug）**：`code.claude.com/docs/en/skills` 的 “Where you write the skill's name” 一节写明：

| 位置 | 例子 | 行为 |
|---|---|---|
| 消息开头 | `/deploy staging` | **直接执行 skill** |
| 普通文字之后、独立单词 | `go ahead and /deploy to staging` | **不直接执行**；该名字只是「本条消息的授权」，模型按措辞自行判断要不要调 |

所以中段提及 = 仅授权、模型自行判断，是**写进文档的设计**（与 `disable-model-invocation` 无关）。要让「点名必读」成立，官方目前没有开关。[#104643](https://github.com/anthropics/claude-code/issues/104643) 仍是 open 的 enhancement，其 Alternative Solutions 明写 “A mod can approximate this”。

**社区追踪**：
| # | 状态（2026-11-12） | 主题 |
|---|---|---|
| **#77868** | ⚫ closed(stale) | 句中被高亮但不派发；作者指出**高亮制造假暗示**。7/7 句中命令全不展开（#87320 统计） |
| **#89802** | 🔴 open（09-23） | 终端 CLI 2.1.280 实测：**命令之前的任何文本都会静默吞掉命令**；命令之后的文本反而有明确报错。文档未写此位置规则 → 无契约可依 |
| **#104643** | 🔴 open（10-23） | 功能请求：任意位置 typeahead + 一条消息里加载所有点名 skill |
| **#93252** | 🔴 open（11-01，0 评论） | 更根本的诉求：hook 只能注入文本，**不能 load 一个 skill**；`additionalContext` 有 10k 字符上限、计入 `/context` 不能、compact 后不 reload、祈使语气会触发 prompt-injection 防御 |

**社区方案（三类，只有第二类确定性）**：
1. **路由注入（主流，概率性）**：`UserPromptSubmit` hook 做意图匹配 → 注入 `<capability-routing>` 让模型知道该调谁。代表 [claude-capability-router](https://github.com/avinashbgmi007-dot/claude-capability-router)、[vstack](https://github.com/itsvedantkumar/vstack)、[travisjneuman/.claude](https://github.com/travisjneuman/.claude) 的 toolkit-router。作者自己在注释里写 “an instruction is a probability”。
2. **确定性注入正文**：mod 可用 `$.session.usage({breakdown:'summary'})` 拿 skill 列表 + `$.skill.prompt({skill})` 取正文 → 写进 `prompt.submit` 的 `context`。**不经过模型判断**，但绕过 Skill 工具：`allowed-tools` 授权、`invoked_skills` 登记、compact 后 re-attach 都不生效。社区暂未见实现（该 API 只有 mod 能用）。**§4 的“强制必读”诉求可行路径就是这个。**
3. **Stop 闸门（事后）**：`Stop` hook 读 transcript，判定“该跑某 skill 却跑了活没跑它”就 block 掉本轮，逼模型补。vstack 的 `skill-mandate.sh` 是代表，能防死循环（`stop_hook_active`）也有逃生门——但只能覆盖能从工具调用判定的规则，且纠正发生在轮末。

对 handoff 的补丁形态（可行、已验证思路）：在 mod 里加 `prompt.submit` hook，扫 `e.text`；若 `e.command` 为空（引擎没解析成命令）且文本里出现了 `/handoff` 这个独立 token，就自己走 watch → compact → resume。命令放哪都生效，代价是要把 `command.run` 里的逻辑抽出来复用，并加标志防止对真正派发的命令重复触发。

**相关 CHANGELOG 动向**：2.1.0 曾加过「`/` 出现在任意位置都弹补全」（#11309 行，仅补全 UI，**不等于派发**）；2.1.265 改进中段命令补全列表；2.1.287 中段 skill 名告知模型；2.1.293 修「粘贴文本里的 skill 名被误当手打」——都是围绕“识别/提示”，**没有一条改了派发规则**。

**复查命令**：
```bash
source ~/.zshrc && proxy on
gh api repos/anthropics/claude-code/issues/104643 --jq '"\(.state) \(.updated_at) c=\(.comments)"'
gh api repos/anthropics/claude-code/issues/93252 --jq '"\(.state) \(.updated_at) c=\(.comments)"'
gh api "search/issues?q=repo:anthropics/claude-code+slash+command+position+in:title&per_page=10" --jq '.items[] | "#\(.number) [\(.state)] \(.title[:80])"'
# 复测最省事：任取一个已注册命令，放句尾发一句，看是否返回命令自身的应答
cd /tmp && claude -p '介绍一下你自己，最后用 /handoff 收尾'
```

---

## 复查速查（一个月后用）

对所有章节，最省力方式：
1. **先刷新 changelog 缓存**（本地 `~/.claude/cache/changelog.md` 会过期，2026-10-16 复查时它停在 10-08 / 2.1.294，而官方已到 2.1.301）：
   ```bash
   source ~/.zshrc && proxy on && curl -sL https://code.claude.com/docs/en/changelog.md -o /tmp/cc-cl.md
   grep -n -i "<关键词>" /tmp/cc-cl.md
   ```
2. 再用 `gh api search/issues` 或 `gh api repos/anthropics/claude-code/issues/<n>` 查对应 issue 是否被 assign / comment 数变化 / 状态翻转。
3. 若某章 issue 已被 fix，用 `claude --version` + `claude update` 确认当前版本是否包含。

**上一次复查结论速览（2026-11-10，对照官方 2.1.322；当时本机 2.1.314）** —— 保留作对照，最新结论看下一张表：
| 章 | 变化 |
|---|---|
| §1 换行 | 无变化（仍停在 2026-10-16 结论），#43113 仍 open |
| §2 copy | 无变化，META #81472 仍 open（2026-11-05 活跃） |
| §3 /init→AGENTS | 无变化，#97004 仍 open 无动作 |
| §4 skill 强读 | 无变化（2.1.287 改进后无新进展），#94564 仍 open（11-06 活跃） |
| §5 假 0 | 无变化，#101314 仍 open 零评论；workaround 保留 |
| §6 翻倍 | **有新动向**：#84738 于 **2026-11-01 收到第三方审计**（2.1.316 受控重放不复现，但非 advisor 路径仍无结论）；官方 CHANGELOG 到 2.1.322 仍无修复词条（2.1.321 只修了估算路径多算工具定义）；**仍未解决**，阈值语义不变：**min(模型窗口, env) − 20k 后 × ~0.8** |
| §7 子agent模型（新增） | 机制存在（frontmatter `model:` / Agent `model` 参数 / `CLAUDE_CODE_SUBAGENT_MODEL`），但 2.1.223+ 有静默丢弃回归 #85592；2.1.316 新增 `CLAUDE_CODE_SUBAGENT_EFFORT`（只控 effort）；设置后需自验生效 |

**2026-11-12 复查（本机升到 2.1.322；官方最新仍 2.1.322，自 11-10 无新版）**：
| 章 | 变化 |
|---|---|
| §1 换行 | **无变化**。#43113 仍 open（10-11，16 评论）；CHANGELOG 到 2.1.322 搜不到 soft-wrap / outputWrapping / no-wrap，全是零散的 UI 换行小修 |
| §2 copy | **仍有活跃修复，但 META 未关**。#81472 仍 open（11-05，14 评论）；期间已修若干具体场景：2.1.176（tmux over SSH 不到剪贴板）、2.1.224（Wayland copy-on-select 竞态）、2.1.275（`--resume` 选择器里鼠标选中不进剪贴板）。本机 **2.1.322 已包含 2.1.176 的 tmux+SSH 修复**——若 §2 的症状还在，值得在 2.1.322 上重测一次再决定是否继续跟 |
| §3 /init→AGENTS | **无变化**。#97004 仍 open（09-25，0 评论）；2.1.277 引入 AGENTS.md 读取、2.1.281 扩到 Bedrock/Vertex/Foundry/网关，但**没有一条给 `/init` 加生成 AGENTS.md 的开关** |
| §4 skill 强读 | **无官方变化**。#104643 仍 open（10-23，enhancement）；#93252（hook 不能 load skill）11-01 更新仍 0 评论；#94564 仍 open，且 **11-06 有人在 2.1.319 上带最小复现确认跨进程 resume 仍丢 skill**（见 §4 注） |
| §5 假 0 | **无变化**。#101314 仍 open（10-11，0 评论）；CHANGELOG 无 synthetic/statusline 相关修复。⚠️ workaround 继续保留（`~/.claude/scripts/statusline.sh` 的 per-session 缓存） |
| §6 翻倍 | **无变化，仍 open**。#84738 最后活动停在 11-01（CBEPX 的第三方审计：92 个放大样本全是「两次 message iteration + 一次 advisor」；2.1.316 受控重放不复现，但**未测非 advisor 路径**）；2.1.318/319 无相关词条。阈值语义不变：**min(模型窗口, env) − 20k 后 × ~0.8** |
| §7 子agent模型 | **无直接修复**。#85592 仍 open（09-19，4 评论），回归未修；2.1.317 改了「不同模型的 subagent 用该模型自己的 effort」——属语义收敛，不是 #85592。新增线索：2.1.305 修「subagent 切 fallback 模型后命名错」，2.1.284 修 Explore 在自定义 base_url 下误切 Opus。**结论不变：设置后必须自验** |
| §8 命令必须行首（新增） | 见上文。无派发规则变更的 CHANGELOG 条目；#104643 / #93252 仍 open，均为 enhancement 角度 |

> 相关 issue 都是在 `anthropics/claude-code` 上公开的；状态会随时间变化，复查时以当时搜到的为准。