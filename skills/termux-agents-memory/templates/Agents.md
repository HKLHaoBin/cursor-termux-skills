# Agents

## 记忆文件（必读）

- 路径：工作区根目录 `MEMORY.md`（Termux 上亦可用 `~/MEMORY.md`）
- **每次执行任务前**：先阅读 `MEMORY.md`，再动手。
- **任务中或结束后**：若出现有价值的经验（环境差异、有效做法、踩坑、用户偏好、项目约定），追加写入 `MEMORY.md` 的「经验日志」或相应章节。
- 只记录可复用事实与经验；不要写入密钥、token、密码或完整凭证文件内容。

## 工作方式提醒

- 本工作区为 Termux（Android）用户空间；注意 Bionic、`/tmp` 与 CLI allowlist，详见 `MEMORY.md` 与 cursor-agent-termux Skill。
- 交互启动请走绑定 `/tmp` 的包装脚本（常见命令名 `agent` → `cursor-agent-proot`）。
- 优先沿用记忆中的路径、工具与已知约束，避免重复试错。

## 用户约定（按需保留或删除）

把「必须用某工具、不要用某替代」写在这里，而不是散落在对话里。

示例（仅当用户确实如此要求时保留）：

- 询问日程、待办、提醒时：用本机 `dida` CLI 对滴答清单增删改查，不要只口头规划。清单 ID 现场 `dida project list`，不要写死在本文件。
- GitHub 的 issue / PR：用 `gh`，不要改用网页操作应付。
