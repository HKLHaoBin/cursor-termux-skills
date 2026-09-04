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

## 从零安装

不要假设手机上已经有 Linux、Git、Node 或可用的 Cursor CLI。按顺序做；某步已经做过就跳过。架构必须是 **ARM64**（`aarch64`）。官方 `curl https://cursor.com/install | bash` 在原生 Termux 上会失败（glibc 的 `node` 无法执行），下面用社区包 `cursor-termux`，不要靠改 PATH 去修那个错误。

卡住时：`pkg` / `dpkg` / `tree-sitter` 等 Agent 能自己跑的修复见 `cursor-agent-termux-install`；Shell 空输出见 `cursor-agent-termux`。

### 1. 安装 F-Droid 和 Termux

不要用 Google Play 上的 Termux（源和签名经常不对，后面 `pkg` 会全失败）。

1. 用系统浏览器打开 [https://f-droid.org](https://f-droid.org)，下载并安装 **F-Droid**。若系统拦截未知来源，在设置里允许该浏览器/文件管理器安装应用。
2. 打开 F-Droid，搜索 **Termux**，安装 [Termux](https://f-droid.org/en/packages/com.termux/)（包名 `com.termux`）。
3. 打开 Termux。首次可能申请存储权限，允许。

在 Termux 里确认环境：

```bash
uname -m
test -d /data/data/com.termux && echo termux_ok
echo "PREFIX=${PREFIX:-unset}"
```

`uname -m` 必须是 `aarch64` 或 `arm64`。`PREFIX` 一般是 `/data/data/com.termux/files/usr`。不是 ARM64 则本仓库不覆盖。

授权访问共享存储（可选，后面写文件会用到）：

```bash
termux-setup-storage
```

弹出权限框时选允许。然后：

```bash
ls ~/storage/shared >/dev/null && echo storage_ok
```

### 2. 让 `pkg` 能上网

核对手机时间和时区（差太多会导致全部 HTTPS 镜像 `bad`）。先试：

```bash
pkg update -y
```

若提示选镜像或 `No mirror or mirror group selected`：

```bash
termux-change-repo
```

用音量键/方向键选一组镜像（中国大陆可试 Tsinghua / USTC / BFSU），回车确认，再：

```bash
pkg update -y
```

若 **所有镜像都是 `bad` / `None of the mirrors are accessible`**：

```bash
ping -c 3 8.8.8.8
ping -c 3 baidu.com
date
```

- `8.8.8.8` 通、域名不通：DNS 坏了。系统 Wi‑Fi 里把 DNS 改成 `8.8.8.8` 和 `1.1.1.1`，或：

```bash
printf 'nameserver 8.8.8.8\nnameserver 1.1.1.1\n' > "$PREFIX/etc/resolv.conf"
```

- 全不通：换 Wi‑Fi / 关 VPN / 关代理，重开 Termux。
- 外网通但默认源不行，可手动写源再更新：

```bash
printf 'deb https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main stable main\n' > "$PREFIX/etc/apt/sources.list"
pkg update -y
```

`pkg upgrade` 若问 `openssl.cnf` 选哪个版本：输入 **N** 回车（保留当前文件）。其它 `Y/n` 用 `-y` 避免 Abort：

```bash
pkg upgrade -y
```

同一时间只跑一个 `pkg`/`apt`。出现 `Could not get lock` 或 `dpkg was interrupted` 时，把终端输出交给 Agent，按 `cursor-agent-termux-install` 修，不要并行再开一个安装。

### 3. 安装基础软件

```bash
pkg install -y git curl tar which python make clang pkg-config binutils openssl-tool ripgrep proot nodejs-lts
```

确认：

```bash
git --version
node -v
npm -v
command -v rg
command -v proot
```

`npm` 来自 `nodejs-lts`，不要再去跑官方 Linux 的 Node 安装脚本。

保证用户级命令目录在 PATH 最前（当前 shell 立刻生效，并写入 bashrc）：

```bash
mkdir -p "$HOME/.local/bin" "$HOME/.cursor/skills" "$PREFIX/tmp" "$HOME/tmp"
touch "$HOME/.bashrc"
grep -q 'HOME/.local/bin' "$HOME/.bashrc" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
grep -q 'TMPDIR=' "$HOME/.bashrc" || cat >> "$HOME/.bashrc" <<'EOF'
export TMPDIR="${PREFIX}/tmp"
export TMP="${PREFIX}/tmp"
export TEMP="${PREFIX}/tmp"
mkdir -p "$TMPDIR"
EOF
source "$HOME/.bashrc"
```

### 4. 克隆本仓库

```bash
cd "$HOME"
git clone https://github.com/HKLHaoBin/cursor-termux-skills.git
ls "$HOME/cursor-termux-skills/skills"
```

没有 `git`、或 GitHub 被墙时，用浏览器打开仓库页面下载 ZIP，解压到 `$HOME/cursor-termux-skills`，保证能看到 `skills/cursor-agent-termux-install/SKILL.md`。

### 5. 安装 Cursor Agent CLI

不要执行 `curl https://cursor.com/install | bash` 作为主路径。

```bash
npm install -g cursor-termux
cursor-termux
```

等它跑完。然后编 Termux 上缺失的 native 模块（可能要几分钟，别让手机休眠）：

```bash
chmod +x "$HOME/cursor-termux-skills/skills/cursor-agent-termux-install/scripts/rebuild-termux-natives"
"$HOME/cursor-termux-skills/skills/cursor-agent-termux-install/scripts/rebuild-termux-natives"
```

确认启动器带 preload，且 `--help` 能出来：

```bash
head -n 20 "$HOME/.local/bin/cursor-agent"
"$HOME/.local/bin/cursor-agent" --help
```

`head` 里应出现 `termux-preload.js`。若仍是 `Cannot find module 'tree-sitter'` 或 `No native build was found for platform=android`，把完整输出交给 Agent（Skill：`cursor-agent-termux-install`）。

### 6. 把 `agent` 指到 proot 包装脚本

官方名字 `agent` 没有 Termux preload，也没有把 `/tmp` 绑到可写目录，Shell 工具会假成功。用仓库里的包装脚本：

```bash
cp "$HOME/cursor-termux-skills/skills/cursor-agent-termux/scripts/cursor-agent-proot" "$HOME/.local/bin/cursor-agent-proot"
chmod 755 "$HOME/.local/bin/cursor-agent-proot"
if [ -e "$HOME/.local/bin/agent" ] && [ ! -L "$HOME/.local/bin/agent" ]; then
  mv -f "$HOME/.local/bin/agent" "$HOME/.local/bin/agent.official.bak"
fi
ln -sfn "$HOME/.local/bin/cursor-agent-proot" "$HOME/.local/bin/agent"
hash -r
command -v agent
head -n 5 "$(command -v agent)"
```

`command -v agent` 必须是 `$HOME/.local/bin/agent`，且指向 `cursor-agent-proot`。不要让它指向未打补丁的官方启动器。

放行 Agent 的 Shell（若已有 `~/.cursor/cli-config.json`，只把 `Shell(**)` 加进 `permissions.allow`，不要整文件覆盖）：

```bash
mkdir -p "$HOME/.cursor"
if [ ! -f "$HOME/.cursor/cli-config.json" ]; then
  cat > "$HOME/.cursor/cli-config.json" <<'EOF'
{
  "permissions": {
    "allow": ["Shell(**)"],
    "deny": []
  }
}
EOF
fi
```

### 7. 安装 Skill 并登录

个人（所有项目可用）：

```bash
mkdir -p "$HOME/.cursor/skills"
cp -R "$HOME/cursor-termux-skills/skills/"* "$HOME/.cursor/skills/"
ls "$HOME/.cursor/skills"
```

不要拷到 `~/.cursor/skills-cursor/`（那是 Cursor 内置目录）。

仅某个项目：

```bash
mkdir -p /path/to/your-project/.cursor/skills
cp -R "$HOME/cursor-termux-skills/skills/"* /path/to/your-project/.cursor/skills/
```

登录 Cursor（需要订阅/账号）。Agent 打不开 Android 浏览器，把打印的链接粘到系统浏览器：

```bash
NO_OPEN_BROWSER=1 agent login
agent status
```

之后用包装后的入口启动：

```bash
cd "$HOME"
agent
```

新开一次 Agent 会话后，Skill 才会被读到。也可在对话里直接点名，例如「按 cursor-agent-termux-install 装 CLI」或「按 cursor-agent-termux 修 Shell」。

### 8. 自检

```bash
uname -m
command -v node
command -v cursor-termux
command -v cursor-agent
command -v agent
ls "$HOME/.local/share/cursor-agent/termux-preload.js"
ls "$HOME/.cursor/skills"
touch "$PREFIX/tmp/.write_test" && echo prefix_tmp_ok
agent --help
agent status
```

`agent --help` 应打印 Usage。`agent status` 应显示已登录。之后 Agent 里的 Shell 若仍是空输出、exit 0，按 `cursor-agent-termux` 修，不要再从改 PATH 开始试错。

更新 Agent 后重跑：

```bash
cursor-termux
"$HOME/cursor-termux-skills/skills/cursor-agent-termux-install/scripts/rebuild-termux-natives"
```

并确认 `agent` 仍指向 `cursor-agent-proot`。

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

## 隐私

本仓库是公开的。Skill 只写可复用步骤与占位符，不含 token、账号、清单 UUID、课表或本机硬件指纹。本机事实应写进你自己的 `MEMORY.md`，不要回传到本仓库。

MCP 相关环境变量放在 `~/.config/agent-mcp.env`（权限 `600`），不要提交。

## 许可

[MIT](LICENSE)。
