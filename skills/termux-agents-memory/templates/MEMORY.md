# 工作环境记忆

> 本文件记录环境事实与可复用经验。有价值的新发现请追加于此；执行任务前先阅读。

最后更新：YYYY-MM-DD

## 平台与路径

- **主机**：Termux on Android（内核 / 版本：现场探测）
- **架构**：现场 `uname -m`（常见 aarch64）
- **Workspace / HOME**：`$HOME`（常见 `/data/data/com.termux/files/home`）
- **Termux PREFIX**：`$PREFIX`（常见 `/data/data/com.termux/files/usr`）
- **时区**：填写本机时区（例如 `Asia/Shanghai`）

## Agent CLI

- 启动命令：`agent`（包装脚本应指向 `cursor-agent-proot`）
- 真实启动器：`~/.local/bin/cursor-agent`
- 运行时版本目录：`~/.local/share/cursor-agent/versions/`（列出当前，勿把旧哈希当永久事实）
- Shell：经 proot 绑定 `$PREFIX/tmp:/tmp` 后应可用；详见 cursor-agent-termux Skill
- CLI 配置：`~/.cursor/cli-config.json`（勿把 email/authId 抄进本文件）

## 已安装主要软件

用 `pkg` / `command -v` 填写实际版本。常见：bash、nodejs、python、git、gh、ripgrep、proot、android-tools。

## Shell / PATH 要点

- `~/.local/bin` 是否在 PATH
- `TMPDIR` 是否为 `$PREFIX/tmp`
- 包管理：`pkg` / `apt`

## 运维注意

- 勿直接跑未绑定 `/tmp` 的官方 `agent` 启动器
- 不要把密钥、token、完整凭证写入本文件
- 部分 `/proc` 文件可能 Permission denied

## 工具约定（按需填写）

- 滴答清单：命令 `dida`；清单 **名称** 可写，**ID 现场** `dida project list`
- GitHub CLI：`gh auth status`（不要写 token）
- Shizuku：`rish -c 'id'` 期望 uid=2000

## 经验日志

（按日期追加：踩坑、有效命令、项目约定、用户偏好）

- YYYY-MM-DD：首次勘察；建立本文件。
