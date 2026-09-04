---
name: gh-termux
description: >-
  Install and use GitHub CLI (gh) on Termux/Android: pkg install, device/web
  auth, issues, pull requests, and repo operations. Use when the user mentions
  gh, GitHub CLI, gh pr, gh issue, or needs GitHub work from Termux.
---

# GitHub CLI on Termux

Termux 上用 `gh` 做 issue、PR、仓库操作。认证信息只存在 gh 自己的配置里，不要写入 MEMORY.md 或 git。

## 安装

```bash
pkg install -y gh
gh --version
```

`~/.local/bin` 若另有 gh，确认 `command -v gh` 指向预期二进制。

## 登录

```bash
gh auth status
```

未登录：`gh auth login`。在 Android/Termux 上优先 **HTTPS + 浏览器/device code** 流程，避免假设桌面密钥环可用。

常见 scope（按用户需要，不要索取多余权限）：`repo`、`read:org`、`gist`。以 `gh auth status` 实际输出为准。

不要把 token 粘进对话记录后的 MEMORY；若用户必须粘贴 token，只用 `gh auth login` 的提示输入，不要回写到仓库。

## Agent 约定

用户要求管 GitHub 上的 issue、PR、检查、Release 时：用 `gh`，不要改用纯网页点击应付。

## 常用

```bash
gh repo view
gh issue list
gh pr status
gh pr create --title '...' --body '...'
gh pr checks
gh run list
```

创建 PR 前：看 `git status`、`git diff`、当前分支是否跟踪 remote、相对主分支的提交。需要 push 时用 `git push -u origin HEAD`。

HTTPS remote 在 Termux 上通常比 SSH 省事（除非用户已配好 ssh-key）。

## 不要做的事

- 不要把某 GitHub 用户名写进 Skill 当「本机必须是谁」
- 不要 `git push --force` 到 main/master，除非用户明确要求
- 不要改 git config 的 user.name / user.email，除非用户明确要求
- 不要提交 `~/.config/gh/` 或 token 文件
