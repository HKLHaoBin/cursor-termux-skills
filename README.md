# cursor-termux-skills

面向 [Cursor](https://cursor.com) Agent 的一组 **Termux / Android** 运行经验 Skill。在新设备上装好后，Agent 应按症状匹配对应 Skill，直接实施已知解法，而不是重新探索。

本仓库是社区经验整理，**不是** Cursor 或 Termux 官方文档。

## 包含的 Skill

| 目录 | 何时用 |
|------|--------|
| `cursor-agent-termux-install` | 官方安装器在 Termux 上还跑不起来：glibc `node` 无法执行、pkg 源、dpkg、cursor-termux、tree-sitter 原生模块 |
| `cursor-agent-termux` | 已经能启动之后：Shell 假成功、`/tmp` 不可写、proot、MCP Bearer 为空 |
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

安装后重启 Agent 会话。也可在对话里直接点名 Skill，例如「按 cursor-agent-termux-install 装 CLI」或「按 cursor-agent-termux 修 Shell」。

## 仓库结构

```
cursor-termux-skills/
├── README.md
├── LICENSE
└── skills/
    ├── cursor-agent-termux-install/
    ├── cursor-agent-termux/
    ├── termux-agents-memory/
    ├── dida-cli/
    ├── gh-termux/
    └── termux-shizuku/
```

## 安装 Cursor CLI 之前（需要人动手）

`cursor-agent-termux` 管的是 **已经能启动之后** 的 Shell / MCP。第一次从官方安装器装到 `cursor-agent --help` 能跑，见 Skill `cursor-agent-termux-install`。下面这些 **Agent 没法替你点**，要人在手机上处理；能自动跑的命令只写在 Skill 里。

1. **不要靠改 PATH 修 `cannot execute: required file not found`。** 官方脚本下发的是 Linux glibc 的 `node`，Termux 是 Android Bionic。PATH 已经对了也执行不了。要用社区包 `cursor-termux`，或到电脑 / 云端跑官方 Agent，或 `proot-distro` 里装真正的 Linux。
2. **Termux 用 F-Droid 版**，不要用 Google Play 旧包（源和签名经常不对，`pkg` 会全失败）。
3. **`pkg update` 所有镜像都是 `bad`。** 先确认手机有网；DNS 可改 `8.8.8.8`；核对系统时间；再跑 `termux-change-repo` 选一组镜像。全不通时 Agent 写 sources.list 也没用，换 Wi‑Fi / 关代理后再试。
4. **`openssl.cnf` 配置文件冲突提示。** 选 **N**（保留当前文件）回车。不要卡在 `Y/I/N/O/D/Z`。
5. **登录。** 在 Termux 跑 `NO_OPEN_BROWSER=1 cursor-agent login`，把打印的链接粘到系统浏览器完成授权。
6. **编译 tree-sitter 时别让手机休眠。** 原生模块编译可能要几分钟。

Agent 能自己做的（`pkg install -y`、修 dpkg lock、`cursor-termux`、`npm install-scripts approve` + `rebuild`、把 `agent` 指到带 preload 的启动器）写在 `cursor-agent-termux-install`，不在 README 重复。

## 隐私

本仓库是公开的。Skill 只写可复用步骤与占位符，不含 token、账号、清单 UUID、课表或本机硬件指纹。本机事实应写进你自己的 `MEMORY.md`，不要回传到本仓库。

MCP 相关环境变量放在 `~/.config/agent-mcp.env`（权限 `600`），不要提交。

## 许可

[MIT](LICENSE)。
