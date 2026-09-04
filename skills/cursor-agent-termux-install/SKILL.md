---
name: cursor-agent-termux-install
description: >-
  Bootstrap Cursor Agent CLI on Termux before it can run: official linux-arm64
  node "cannot execute: required file not found", pkg mirrors all bad, dpkg
  lock/interrupted, openssl.cnf prompt, cursor-termux smoke test missing
  tree-sitter, npm allowScripts blocking native rebuild, agent vs cursor-agent
  musl MODULE_NOT_FOUND. Use when installing agent/cursor-termux on Android
  aarch64, or when `agent` fails before --help works.
---

# 安装 Cursor Agent CLI（Termux）

官方 `curl https://cursor.com/install | bash` 下发的是 **linux/arm64 glibc** 的 `node`。Termux 是 Android **Bionic**，没有 `/lib/ld-linux-aarch64.so.1`，所以会出现：

```text
.../versions/<ver>/node: cannot execute: required file not found
```

这 **不是 PATH 问题**。再 `echo 'export PATH=...' >> ~/.bashrc` 解决不了。

本 Skill 覆盖 **第一次装到 `cursor-agent --help` 能跑**。已经能启动、但 Shell 假成功 / `/tmp` / MCP，改走 [`cursor-agent-termux`](../cursor-agent-termux/SKILL.md)。

从零环境（F-Droid Termux、`pkg`、克隆本仓库、装 CLI）的完整命令见仓库 README「从零安装」。下面默认 Agent 在 **用户的 Termux 交互 shell** 里执行；人没法点的步骤（换网络、选镜像、openssl 提示、浏览器登录）仍要交给用户。

## 何时使用

- `agent` / 官方安装器报 `cannot execute: required file not found`
- `pkg update` / `pkg install` 镜像全 `bad`，或 `npm: command not found`
- `dpkg was interrupted`、`Could not get lock ... lock-frontend`
- `cursor-termux` smoke test 报 `Cannot find module 'tree-sitter'`
- `npm error Unknown cli flag: --build-from-source`
- `No native build was found for platform=android`
- `Cannot find module '@anysphere/file-service-linux-arm64-musl'`（跑了官方 `agent` 而不是带 preload 的 `cursor-agent`）

## 诊断（按顺序）

```bash
echo "PREFIX=${PREFIX:-unset}"
uname -m
test -d /data/data/com.termux && echo termux_ok
command -v node; node -v 2>/dev/null
command -v npm
command -v cursor-termux
command -v cursor-agent
command -v agent
type -a agent 2>/dev/null
ls -l "$(command -v agent)" "$(command -v cursor-agent)" 2>/dev/null
date
ping -c 1 8.8.8.8 || true
```

- `uname -m` 必须是 `aarch64` / `arm64`。其它架构本仓库不覆盖。
- 官方 bundled `node` 不可执行是预期；要用 Termux 的 `$PREFIX/bin/node`。

## 落地顺序

### 1. 包管理器可用后再装 Node

一律带 `-y`，避免确认提示被 Abort：

```bash
pkg update -y
pkg install -y nodejs-lts
command -v npm && node -v
```

**镜像全 `bad` / `None of the mirrors are accessible`：** Agent 改 sources.list 也救不了「手机没网」。交给用户（README）。若只是当前镜像挂了、外网通，可写源再 `pkg update -y`：

```bash
printf 'deb https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main stable main\n' > "$PREFIX/etc/apt/sources.list"
pkg update -y
```

**`Could not get lock ... held by process PID (apt)`：**

1. `ps -p PID -o pid,cmd`（或 `ps aux | grep -E 'apt|dpkg'`）。
2. 另一个会话正在装包 → **等它结束**，不要并行 `pkg`。
3. 确认卡住/残留 → `kill PID`，仍在则 `kill -9 PID`。
4. 确认没有 apt/dpkg 后再装。只有确认无进程时才删 lock：

```bash
rm -f "$PREFIX/var/lib/dpkg/lock-frontend" "$PREFIX/var/lib/dpkg/lock" "$PREFIX/var/cache/apt/archives/lock"
dpkg --configure -a
```

**`E: dpkg was interrupted, you must manually run 'dpkg --configure -a'`：**

```bash
DEBIAN_FRONTEND=noninteractive dpkg --configure -a
apt -f install -y
```

非交互时保留已有配置文件，避免卡在 `openssl.cnf`：

```bash
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confold" -y install nodejs-lts
```

若用户已经在交互提示里：选 **N**（保留当前 `openssl.cnf`）。这步 Agent 代选不了，见 README。

### 2. 用 cursor-termux 打 Bionic 兼容层

```bash
npm install -g cursor-termux
cursor-termux
```

这是社区包装（symlink Termux `node`/`rg` + preload），不是官方 Android 构建。装完应有：

- `~/.local/bin/cursor-agent`（带 `termux-preload.js`）
- `~/.local/share/cursor-agent/versions/<ver>/`

`cursor-termux` 会清掉版本目录。若刚编过 native 模块，装完必须再编一次。

### 3. 补 tree-sitter 原生模块

新版 Agent 的 `index.js` 会 `require('tree-sitter')` 等。npm 默认 **拦住 install scripts**，只下载 JS、不编译，接着：

- `Cannot find module 'tree-sitter'`
- 或 `No native build was found for platform=android arch=arm64 ...`

**不要**用 `npm install --build-from-source`（新 npm：`EUNKNOWNCONFIG`）。

```bash
VERDIR="$(ls -d "$HOME"/.local/share/cursor-agent/versions/* | tail -n 1)"
cd "$VERDIR"
npm install tree-sitter --foreground-scripts
npm install-scripts approve tree-sitter
npm rebuild tree-sitter --foreground-scripts
```

再缺语言包（常见 `tree-sitter-bash`）。先探测再装，不要猜一长串：

```bash
grep -oE 'tree-sitter-[a-z0-9-]+' "$VERDIR/index.js" | sort -u
```

对每个缺的模块：`npm install <name> --foreground-scripts` → `npm install-scripts approve <name>` → `npm rebuild <name> --foreground-scripts`。

也可用本目录 [`scripts/rebuild-termux-natives`](scripts/rebuild-termux-natives)：缺什么补什么，直到 `cursor-agent --help` 成功。编译期间让用户别让手机休眠。

编译依赖（cursor-termux 通常已装）：`python` `make` `clang` `pkg-config`。

### 4. `agent` 必须走 preload，不能走官方启动器

`--help` 通了之后，PATH 上的 `agent` 若仍是官方脚本，会报：

```text
Cannot find module '@anysphere/file-service-linux-arm64-musl'
```

官方启动器可备份后改指向带 preload 的启动器：

```bash
mkdir -p "$HOME/.local/bin"
mv -f "$HOME/.local/bin/agent" "$HOME/.local/bin/agent.official.bak" 2>/dev/null || true
ln -sf "$HOME/.local/bin/cursor-agent" "$HOME/.local/bin/agent"
grep -q 'HOME/.local/bin' "$HOME/.bashrc" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
hash -r
command -v agent
head -n 20 "$(command -v agent)"
```

`head` 里应出现 `termux-preload.js` / `VERSION_DIR`。若 `type -a agent` 还有更靠前的官方路径，修 PATH 或删掉那个文件。

装通之后，**推荐**再按 [`cursor-agent-termux`](../cursor-agent-termux/SKILL.md) 把 PATH 上的 `agent` 换成 `cursor-agent-proot`（绑可写 `/tmp`）。包装脚本必须 `exec` 真实的 `~/.local/bin/cursor-agent`，禁止再 `exec agent`。

### 5. 登录

```bash
NO_OPEN_BROWSER=1 cursor-agent login
```

把打印的 URL 交给用户在系统浏览器打开。Agent 打不开 Android 浏览器。

```bash
cursor-agent status
cursor-agent --help
```

## Agent 更新之后

`cursor-agent update` 或重跑 `cursor-termux` 会换版本目录、丢掉 native 补丁。然后：

1. 再跑 `cursor-termux`（preload / Merkle stub）
2. 再跑 `rebuild-termux-natives`（tree-sitter）
3. 确认 `agent` 仍指向带 preload 的启动器（或 proot 包装）

不要把某次版本哈希（如 `2026.08.31-4057e58`）写进记忆当永久路径；用 `ls -d ~/.local/share/cursor-agent/versions/*`。

## 不要做的事

- 不要靠反复改 PATH 修 `cannot execute: required file not found`
- 不要并行两个 `pkg`/`apt`
- 不要在仍有 apt 进程时删 dpkg lock
- 不要用 `npm install --build-from-source`（改 `install-scripts approve` + `npm rebuild`）
- 不要让用户继续用未打补丁的官方 `~/.local/bin/agent` 当入口
- 不要把 token、登录 Cookie、完整 `auth.json` 写入本 Skill 或 MEMORY

## 验证清单

- [ ] Termux `node` / `npm` 可用（`command -v node` 在 `$PREFIX/bin`）
- [ ] `cursor-agent --help` 打印 Usage，不再 MODULE_NOT_FOUND
- [ ] `head ~/.local/bin/cursor-agent` 加载 `termux-preload.js`
- [ ] 用户若要输入 `agent`，PATH 上的 `agent` 不是官方 glibc 启动器
- [ ] 登录：`cursor-agent status` 已认证（URL 由用户在浏览器完成）
