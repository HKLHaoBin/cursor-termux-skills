# 参考：Termux 上首次安装 Agent CLI

主流程见 [SKILL.md](SKILL.md)。这里只放背景与次要症状。

## 根因

| 现象 | 原因 |
|------|------|
| bundled `node`: required file not found | ELF interpreter `/lib/ld-linux-aarch64.so.1`（glibc）在 Bionic/Termux 不存在 |
| 所有 Termux 镜像 `bad` | 没网、DNS、系统时间错误、或 Play 版 Termux 源不对；不是 Cursor 的问题 |
| `pkg install` Abort | 确认提示未回 `Y`；Agent 应始终 `pkg install -y` |
| lock-frontend held by apt | 另一个 `pkg`/`apt` 未结束，或上次安装被杀留下进程 |
| dpkg interrupted | 上次 `pkg` 中途 Abort/杀进程 |
| `Unknown cli flag: --build-from-source` | npm 9+/新 CLI 不认该 flag；改为 approve install scripts 后 `npm rebuild` |
| install scripts blocked | 新 npm 默认 `ignore-scripts`；`tree-sitter` 只有 JS、没有 `.node` |
| No native build for platform=android | 脚本没跑或编失败；`node-gyp rebuild` 成功后应有 `build/Release/*.node` |
| `tree-sitter-bash` MODULE_NOT_FOUND | Agent 还会 require 语言包；`grep index.js` 再装，不要一次猜所有语言 |
| file-service-linux-arm64-musl | Termux 被当成 musl；必须走 cursor-termux 的 preload。官方 `agent` 启动器没有 `-r termux-preload.js` |

## 探路命令

```bash
file "$(ls "$HOME"/.local/share/cursor-agent/versions/*/node 2>/dev/null | head -1)" 2>/dev/null || true
head -n 30 "$HOME/.local/bin/cursor-agent"
ls -l "$HOME/.local/share/cursor-agent/termux-preload.js"
npm install-scripts ls
```

## 更稳但不在本 Skill 范围

- `proot-distro` 里装 Ubuntu/Debian，再跑官方 `curl https://cursor.com/install | bash`（真正的 glibc userland）
- 电脑或云端 Linux 跑官方 Agent；手机只用 SSH / [cursor.com/agents](https://cursor.com/agents)

## 产品改名

CLI 对外可能叫 **Agent**，目录仍常含 `cursor-agent`。修入口时看文件内容（preload），不要只看命令名。
