---
name: cursor-agent-termux
description: >-
  Diagnose and fix Cursor Agent CLI on Termux/Android: empty Shell stdout with
  exit 0, no file side effects, unwritable /tmp, proot bind, cursor-termux
  patches, allowlist Shell(**), and MCP Bearer env empty causing 401 then SSE
  405. Use when the user is on Termux, Android aarch64, agent/cursor-agent,
  cursor-agent-proot, or reports Shell fake-success.
---

# Cursor Agent on Termux

在 Termux（Android，Bionic，常见 aarch64）上跑官方 Agent CLI。系统 `/tmp` 对 Termux 用户通常不可写；Agent 的 Shell 工具若把临时文件写到 `/tmp`，会 **假成功**：exit 0、无 stdout、无文件副作用。

若 `agent` 还不能 `--help`（glibc `node` 无法执行、缺 `nodejs-lts`、`cursor-termux` smoke test 缺 `tree-sitter`），先按 [`cursor-agent-termux-install`](../cursor-agent-termux-install/SKILL.md) 装通，再回到本 Skill。

只做下面的诊断与落地，不要从「改 TMPDIR 再重启看看」重新试错。仅设 TMPDIR 或仅放宽 allowlist **不够**。

## 何时使用

- 用户在 Termux / Android 上使用 `agent` / `cursor-agent`
- Shell 命令空输出、exit 0、探针文件没写出来
- 提到 `/tmp`、proot、`cursor-termux`、`cursor-agent-proot`
- MCP 显示 0 tools、401、或 `SSE error: Non-200 status code (405)`

## 诊断（先做，按顺序）

在 **Termux 交互 shell**（不是 Agent 内的假 Shell）执行。路径一律用 `$HOME`、`$PREFIX`。

1. **是否在 Termux**

```bash
echo "PREFIX=${PREFIX:-unset}"
uname -m
test -d /data/data/com.termux && echo termux_ok
```

2. **`agent` 实际指向哪里**

```bash
command -v agent
command -v cursor-agent
command -v cursor-agent-proot
ls -l "$(command -v agent)" "$(command -v cursor-agent)" 2>/dev/null
```

- PATH 上的 `agent` 必须是 **proot 包装脚本**（或指向它的 symlink），不能是未绑定 `/tmp` 的官方启动器。
- 别名未展开时（非交互、`env -i`、Agent 自己 spawn）只会走 PATH。所以 **symlink/PATH 必须对**，不能只靠 `.bashrc` 别名。

3. **proot 与可写 tmp**

```bash
command -v proot || pkg install -y proot
mkdir -p "$PREFIX/tmp" "$HOME/tmp"
touch "$PREFIX/tmp/.write_test" && echo prefix_tmp_ok
touch /tmp/.write_test 2>/dev/null && echo system_tmp_ok || echo system_tmp_fail
```

`system_tmp_fail` 是预期。修复靠 `proot -b $PREFIX/tmp:/tmp`，不是靠 Agent 去写系统 `/tmp`。

4. **是否已经在 proot 里**

```bash
# 包装脚本内应看到 /tmp 与 $PREFIX/tmp 同源
proot -b "${PREFIX}/tmp:/tmp" /system/bin/realpath /tmp 2>/dev/null || true
```

5. **allowlist**

读 `~/.cursor/cli-config.json`。`permissions.allow` 需含 `Shell(**)`，否则命令会卡审批（这是另一类问题，与空 stdout 不同）。

6. **日志**（确认「命令发出去了但没副作用」）

```bash
ls -dt "$PREFIX"/tmp/cursor-agent-logs-* 2>/dev/null | head -3
```

日志里有 `Executing shell command`、allowlist 已放行、CWD 正确，但仍无 stdout → **不是没重启**，是执行/捕获层（`/tmp`）失效。

## 落地三件套（缺一不可）

### 1. TMPDIR 指向 Termux 可写目录

`.bashrc`（或 `.profile`）中：

```bash
export TMPDIR="${PREFIX}/tmp"
export TMP="${PREFIX}/tmp"
export TEMP="${PREFIX}/tmp"
mkdir -p "$TMPDIR"
```

启动器里也要 export，因为 Agent 往往不是从交互 bashrc 起来的。

可选：`export LD_LIBRARY_PATH="$PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"`（glibc 二进制靠 cursor-termux 补丁时有用）。

### 2. 允许 Shell

编辑 `~/.cursor/cli-config.json`，确保类似：

```json
{
  "permissions": {
    "allow": ["Shell(**)"],
    "deny": []
  }
}
```

不要提交这份文件里的账号、email、authId。

### 3. proot 绑定后再启动 Agent

1. 安装：`pkg install -y proot`
2. 用 npm 包 **cursor-termux** 安装/补丁官方 linux-arm64 Agent（Bionic 需要 symlink/preload）。
3. 把本 Skill 的 [`scripts/cursor-agent-proot`](scripts/cursor-agent-proot) 安装为可执行文件，例如 `~/.local/bin/cursor-agent-proot`。
4. PATH 上的 `agent` → 该包装脚本；真实 Node 启动器保持 `~/.local/bin/cursor-agent`（或官方备份名）。
5. **包装脚本必须用绝对路径 exec `cursor-agent`，禁止再调 `agent`**，否则递归。

交互别名可作冗余：

```bash
alias agent='cursor-agent-proot'
alias cursor-agent='cursor-agent-proot'
```

装好后 **用包装脚本重启 Agent**，再测：

```bash
echo SHELL_OK
echo probe > "$HOME/tmp/agent-shell-probe.txt"
```

Agent 内应能看到 `SHELL_OK`，且探针文件存在。

## 启动路径（对）

```
用户输入 agent
  → PATH: cursor-agent-proot
    → export TMPDIR=$PREFIX/tmp
    → 可选 source ~/.config/agent-mcp.env
    → exec proot -b $PREFIX/tmp:/tmp ~/.local/bin/cursor-agent
```

## 启动路径（错）

- 直接跑 `~/.local/bin/agent` 且它只是官方启动器、未绑 `/tmp`
- `alias agent='cursor-agent'` 盖住 PATH，非交互时又绕过别名
- 包装脚本 `exec agent` → 再进包装脚本

官方启动器可备份为例如 `~/.local/bin/agent.official.bak`，不要让它抢 `agent` 这个名字。

## Agent 更新之后

重跑 `cursor-termux` 打补丁。版本目录会变（`~/.local/share/cursor-agent/versions/...`），**tree-sitter 等 native 也会被清掉**，按 [`cursor-agent-termux-install`](../cursor-agent-termux-install/SKILL.md) 再编一次。用探测，不要把某次哈希写死进记忆当永久事实。

```bash
ls -d "$HOME"/.local/share/cursor-agent/versions/* 2>/dev/null
```

## MCP：Bearer 空导致 401，再误走 SSE 得到 405

`mcp.json` 里 `"Authorization": "Bearer ${env:SOME_TOKEN}"` 时，Agent 进程里该变量经常是空的（非交互、没 source bashrc）→ `POST /mcp` **401** → 客户端改走 OAuth/SSE → `GET /mcp` 对 Streamable HTTP 端点是 **405**，UI 像 `SSE error: Non-200 status code (405)`。

处理：

1. 在 **proot 包装脚本**里 `export` 该变量，或 `source ~/.config/agent-mcp.env`（`chmod 600`，不要提交、不要写入 MEMORY.md）。
2. 不要把字面 token 写进 git 里的 `mcp.json`。
3. 重启 Agent 后再看日志：`$PREFIX/tmp/cursor-agent-logs-*/session-*.log` 应出现 `POST /mcp` 200/202。
4. 若 `GetDynamicTools` 仍没有该 MCP 命名空间，可用 Shell + `curl` 对端点做 JSON-RPC（initialize / tools/list / tools/call）作为后备。偶发的 `GET /mcp` 405 可忽略，只要 POST 成功。

示例 `~/.config/agent-mcp.env`（占位符，不要提交真实值）：

```bash
# export SOME_MCP_TOKEN="replace-me"
```

## 工作目录也会导致空输出

工作区路径失效或被改名时，Shell 也可能 exit 0 + 空 stdout。解法：从正确路径打开 workspace，或让 Agent 使用绝对路径 CWD。详见 [reference.md](reference.md)。

## 不要做的事

- 不要把 token、Bearer、完整 `auth.json`、email 写入 MEMORY 或本 Skill 的提交
- 不要假设系统 `/tmp` 可写
- 不要在无 proot 时宣称「Shell 已修好」
- 不要把某台手机的 CPU part、内存、Agent 版本哈希当成所有设备的固定值；需要时现场探测

## 验证清单

- [ ] `command -v agent` 指向 proot 包装脚本
- [ ] `proot` 已安装
- [ ] `$PREFIX/tmp` 可写
- [ ] `cli-config` 含 `Shell(**)`
- [ ] 经包装脚本启动后，Agent Shell 有 stdout 且能写探针文件
- [ ] MCP 若使用 `${env:...}`，包装脚本已 export；日志 POST 非 401
