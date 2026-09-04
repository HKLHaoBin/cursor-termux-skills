# 参考：Termux 上 Agent Shell 空输出

主流程见 [SKILL.md](SKILL.md)。这里只放背景与次要症状。

## 探测本机（不要把结果写进公开仓库）

```bash
uname -a
nproc
head -5 /proc/cpuinfo 2>/dev/null || true
grep -E 'MemTotal|MemAvailable' /proc/meminfo 2>/dev/null || true
node -v 2>/dev/null
command -v cursor-termux
ls -d "$HOME"/.local/share/cursor-agent/versions/* 2>/dev/null
```

部分 `/proc` 文件（如 `/proc/version`）可能 Permission denied；`/proc/cpuinfo`、`/proc/meminfo` 通常可读。

## 社区同类现象

1. **Cursor 论坛**：工作目录失效/被改名时，Shell 静默假成功（空输出、exit 0）。从正确路径重新打开 workspace，或明确使用绝对路径 CWD。
2. **Termux / 其它 Android AI CLI**：系统 `/tmp` 不可写。`TMPDIR`/`TMP`/`TEMP=$PREFIX/tmp`，必要时 `proot -b $PREFIX/tmp:/tmp`。
3. **cursor-termux**：Agent 更新后重跑安装器打补丁；常用 `--trust`。不要指望上游有专门「Shell 空输出」issue。
4. **allowlist 过窄**：会卡审批，不是空 stdout。`Shell(**)` 或等价 unrestricted。若日志已 unrestricted 仍空输出 → 不是审批问题。
5. **更稳但不在本 Skill 范围**：`proot-distro` glibc 或云端 Linux 跑官方 Agent，手机 Termux 只做 SSH。

## 可忽略的噪音

启动日志里 `cursorsandbox` `spawnSync … ENOENT`（版本目录下没有该二进制）、`isSandboxAvailable: false` 在 Termux 上常见。sandbox 不可用时，修好 `/tmp` 绑定后 `insecure_none` 仍应有真实 Shell 输出。不要把 ENOENT 当成主因。

## 产品改名

CLI 对外名称可能是 **Agent**，路径与配置目录仍常含 `cursor-agent`。包装脚本应 exec 真实启动器文件（常见 `~/.local/bin/cursor-agent`），不要依赖产品显示名。

## 权限模型

Termux 是应用用户空间，不是完整 GNU/Linux。官方 Agent 的 linux-arm64 **glibc** 二进制依赖 cursor-termux 的兼容层。包管理用 `pkg` / `apt`。
