# cursor-termux-skills

面向 [Cursor](https://cursor.com) Agent 的一组 **Termux / Android** 运行经验 Skill。在新设备上装好后，Agent 应按症状匹配对应 Skill，直接实施已知解法，而不是重新探索。

本仓库是社区经验整理，**不是** Cursor 或 Termux 官方文档。

## 包含的 Skill

| 目录 | 何时用 |
|------|--------|
| `cursor-agent-termux` | Agent CLI 在 Termux 上 Shell 假成功、`/tmp` 不可写、proot、MCP Bearer 为空 |
| `termux-agents-memory` | 新工作区要铺 `MEMORY.md` + `Agents.md` + 记忆规则 |
| `dida-cli` | 滴答清单 / TickTick 的 `dida` CLI 增删改查 |
| `gh-termux` | Termux 上安装与使用 GitHub CLI |
| `termux-shizuku` | Shizuku `rish`、ADB 级权限、从 Termux 装 APK |

## 安装

把 `skills/` 下各目录复制到 Cursor skills 路径（目录名保持不变，内含 `SKILL.md`）：

**个人（所有项目可用）**

```bash
git clone https://github.com/HKLHaoBin/cursor-termux-skills.git
cp -R cursor-termux-skills/skills/* ~/.cursor/skills/
```

**仅当前项目**

```bash
mkdir -p .cursor/skills
cp -R /path/to/cursor-termux-skills/skills/* .cursor/skills/
```

不要安装到 `~/.cursor/skills-cursor/`（那是 Cursor 内置 skills 目录）。

安装后重启 Agent 会话。也可在对话里直接点名 Skill，例如「按 cursor-agent-termux 修 Shell」。

## 仓库结构

```
cursor-termux-skills/
├── README.md
├── LICENSE
└── skills/
    ├── cursor-agent-termux/
    ├── termux-agents-memory/
    ├── dida-cli/
    ├── gh-termux/
    └── termux-shizuku/
```

## 隐私

本仓库是公开的。Skill 只写可复用步骤与占位符，不含 token、账号、清单 UUID、课表或本机硬件指纹。本机事实应写进你自己的 `MEMORY.md`，不要回传到本仓库。

MCP 相关环境变量放在 `~/.config/agent-mcp.env`（权限 `600`），不要提交。

## 许可

[MIT](LICENSE)。
