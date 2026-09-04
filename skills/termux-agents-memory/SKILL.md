---
name: termux-agents-memory
description: >-
  Bootstrap MEMORY.md, Agents.md, and an always-apply Cursor rule for Termux
  workspaces. Use when setting up a new Android/Termux device, when the user
  asks for a memory file, Agents.md, agent rules, or a reusable experience log,
  or when the workspace has no MEMORY.md yet.
---

# Termux 记忆与 Agents 规则

在新设备或新工作区铺一套 **可复用、不含密钥** 的记忆框架。本机已有私人 `MEMORY.md` 时不要覆盖，只补缺失文件或按用户要求增量改。

## 何时使用

- 新 Termux 工作区、用户说「记忆文件」「Agents 规则」「经验日志」
- 工作区根目录没有 `MEMORY.md` 或 `Agents.md`
- 要把运行经验留下来给后续会话，而不是只留在对话里

## 落地文件

在工作区根目录（Termux 上常常就是 `$HOME`）：

| 文件 | 作用 |
|------|------|
| `MEMORY.md` | 本机事实与经验日志；任务前必读 |
| `Agents.md` | 用户约定与工作方式（偏好、强制工具） |
| `.cursor/rules/memory-workflow.mdc` | `alwaysApply: true`，提醒 Agent 读/写记忆 |

复制本 Skill 的模板：

- [templates/MEMORY.md](templates/MEMORY.md)
- [templates/Agents.md](templates/Agents.md)
- [templates/memory-workflow.mdc](templates/memory-workflow.mdc)

复制后把占位符换成 **这台设备现场探测** 的值。路径写 `$HOME` / `$PREFIX` / `~/...`，避免把某台机器的绝对私有细节当成通用真理。

## Agent 必须遵守

1. **任务前**阅读 `MEMORY.md`，再动手。
2. **任务中或结束后**：有价值的环境差异、有效做法、踩坑、用户偏好、项目约定 → 追加到「经验日志」或对应章节。
3. **禁止**写入密钥、token、密码、Bearer、完整凭证文件内容。
4. 用户偏好与强制工作流写 `Agents.md`；易变本机事实写 `MEMORY.md`。
5. 清单 ID、课表、账号名若必须记，只放本机 `MEMORY.md`，不要提交到公开仓库。

## 探测后填 MEMORY（示例命令）

```bash
uname -m
echo "HOME=$HOME PREFIX=${PREFIX:-unset}"
command -v agent; command -v gh; command -v dida; command -v rish
pkg list-installed 2>/dev/null | head
```

只记录对后续任务有用的版本与路径。硬件指纹、内存瞬时值可记「约数 + 探测命令」，不要当永久常量。

## 与其它 Skill 的分工

- Shell / proot / `/tmp` → `cursor-agent-termux`
- 滴答清单命令 → `dida-cli`；是否「日程必须走 dida」写在 **本机** `Agents.md`
- `gh` → `gh-termux`
- Shizuku → `termux-shizuku`

## 不要做的事

- 不要把本 Skill 的空白模板当成已经填好的私人记忆
- 不要在公开 git 里提交填过 token 的 MEMORY
- 不要创建规则到 `~/.cursor/skills-cursor/`
