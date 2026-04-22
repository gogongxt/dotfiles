---
name: proxy
description: Manage shell proxy environment variables - on, off, toggle, status, and pip/uv proxy helpers
user-invocable: true
---

# Proxy Management

Manage HTTP/HTTPS/FTP/RSYNC proxy environment variables in the current shell session.

## When to Use Proxy

**NOT all network access needs proxy.** Only use proxy for sites that are blocked or slow without it (e.g. GitHub, Google, npmjs.org, PyPI, Docker Hub). Domestic sites (e.g. baidu.com, bing.com, Chinese mirrors) work fine without proxy and may even be slower with it.

### Needs proxy

- GitHub (`gh`, `git push/pull` to github.com)
- Google, YouTube, Twitter, etc.
- npmjs.org, PyPI (pypi.org), Docker Hub
- Hugging Face (though `HF_ENDPOINT=https://hf-mirror.com` is set by default)

### Does NOT need proxy

- baidu.com, bing.com, bilibili.com
- Chinese PyPI/npm mirrors (tsinghua, aliyun, tencent)
- Any `.cn` or domestic services

If the target is a foreign site that may be blocked or slow, add proxy. Otherwise, skip it.

## Shell Session Reminder

Each Bash tool call runs in a **new shell session** — environment variables do NOT persist between calls. When proxy is needed, chain it inline:

```bash
source ~/.zshrc && proxy on && <your-command>
```

Do NOT assume proxy is active from a previous call.

## Commands

| Command                           | Description                             |
| --------------------------------- | --------------------------------------- |
| `source ~/.zshrc && proxy on`     | Enable proxy                            |
| `source ~/.zshrc && proxy off`    | Disable proxy, unset all proxy env vars |
| `source ~/.zshrc && proxy toggle` | Toggle proxy on/off                     |
| `source ~/.zshrc && proxy status` | Show current proxy env vars status      |

### Custom Proxy Address

```bash
source ~/.zshrc && proxy on 192.168.1.1:8080
```

Override `PROXY_DEFAULT` by setting the `PROXY` env var in `.zshrc`.

## Environment Variables Set

When proxy is on, these are set:

- `http_proxy` / `HTTP_PROXY`
- `https_proxy` / `HTTPS_PROXY`
- `ftp_proxy` / `FTP_PROXY`
- `rsync_proxy` / `RSYNC_PROXY`

## Pip / Uv Proxy Helpers

Run pip/uv through proxy using official PyPI source:

```bash
source ~/.zshrc && pip_proxy install <package>
source ~/.zshrc && uv_proxy install <package>
```

Use China mirror sources (no proxy, faster locally):

```bash
source ~/.zshrc && pip_tsinghua install <package>   # Tsinghua mirror
source ~/.zshrc && pip_aliyun install <package>      # Aliyun mirror
source ~/.zshrc && pip_tencent install <package>     # Tencent mirror
source ~/.zshrc && uv_tsinghua install <package>     # Tsinghua mirror
source ~/.zshrc && uv_aliyun install <package>       # Aliyun mirror
source ~/.zshrc && uv_tencent install <package>      # Tencent mirror
```

## Common Patterns

### Network commands that need proxy (foreign sites)

```bash
source ~/.zshrc && proxy on && git push                        # github.com
source ~/.zshrc && proxy on && gh pr create                    # GitHub API
source ~/.zshrc && proxy on && curl https://pypi.org/...       # PyPI
```

### Network commands that do NOT need proxy (domestic sites)

```bash
curl https://www.baidu.com                                    # baidu
curl https://cn.bing.com                                      # bing China
pip_tsinghua install <package>             # Tsinghua mirror
uv_aliyun install <package>                # Aliyun mirror
```

### Local-only commands (no proxy needed)

```bash
git add -A && git commit -m "message"   # local git ops
ls, cat, grep, find                      # local filesystem
```

## Notes

- **Not all network access needs proxy** — only use proxy for foreign sites that are blocked or slow (GitHub, Google, etc.). Domestic sites (baidu, bing, Chinese mirrors) work fine without it
- **Every Bash call is a new shell** — when proxy is needed, chain `source ~/.zshrc && proxy on &&` before the command
- Use `proxy on` explicitly rather than `pt` (toggle alias) to avoid accidentally turning proxy off
- Default proxy address has been set, configurable via `PROXY_DEFAULT` or `PROXY` env var
- `sudo` does NOT inherit proxy env vars — use `sudo -E` if needed
- `HF_ENDPOINT=https://hf-mirror.com` is set by default for Hugging Face downloads
