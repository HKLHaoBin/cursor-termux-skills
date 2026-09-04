---
name: dida-cli
description: >-
  Use the TickTick/滴答清单 CLI (dida, @suibiji/dida-cli) on Termux to list,
  create, update, complete, and delete tasks, habits, and countdowns. Use when
  the user mentions 滴答清单, TickTick, dida, 日程, 待办, 提醒, 习惯, or 倒数日,
  or asks to add/change/delete calendar items via CLI.
---

# 滴答清单 CLI（dida）

用本机命令 `dida`（npm 包 `@suibiji/dida-cli`）对滴答清单做增删改查。先读后写：不确定清单或任务 ID 时先 `project list` / `task search`。

**不要**把 API token 写入 MEMORY.md 或任何 git 文件。Token 只存在 `~/.config/dida-cli/config.json`。

## 安装与登录

```bash
npm install -g @suibiji/dida-cli
command -v dida
dida auth status
```

未登录：

- 有本机浏览器：`dida auth login`（OAuth 回调常见 `http://localhost:8766/callback`，有超时）
- 无浏览器：网页版「头像 → 设置 → 账户与安全 → API 口令」，然后 `dida auth token <token>`（token 只进 CLI 配置，不要回显到记忆文件）

## 清单 ID：现场查询

```bash
dida project list
dida project list --json
```

用返回的 ID 填 `--project`。**不要**把某台设备上的 UUID 写进 Skill 或公开仓库。本机若要缓存名称→ID，只写私人 `MEMORY.md`，并注明会过期、以 `project list` 为准。

未指明清单时：按用户 `Agents.md` 的归类规则；若无约定，问用户或选其默认清单。

## 时区与时间格式

默认按用户时区；中国大陆常用 `Asia/Shanghai`（`+0800`）。

```text
yyyy-MM-ddTHH:mm:ss+0800
```

UTC 写法带 `Z`。换算时不要把本地墙上时钟直接当 UTC。

## 常用命令

```bash
dida auth status
dida project list
dida task search --due-from 'YYYY-MM-DDT00:00:00+0800' --due-to 'YYYY-MM-DDT23:59:59+0800' --status 0
dida task create --title '标题' --project <清单ID> --due-date '...' --time-zone Asia/Shanghai --reminders 'TRIGGER:PT0S'
dida task update <taskId> --id <taskId> --project <清单ID> --title '新标题'
dida task complete <清单ID> <任务ID>
dida task delete <清单ID> <任务ID>
dida habit list
dida countdown list
```

查询加 `--json` 便于解析。批量新增：多次 `dida task create`（无批量子命令）。

提醒：准时 `TRIGGER:PT0S`；提前 15 分钟 `TRIGGER:-PT15M`。优先级常见：`0` 无 / `1` 低 / `3` 中 / `5` 高（以 `dida task create --help` 为准）。

## 时间坑（必须避开）

Open API **同时**传开始时间与截止时间时，往往 **只保留截止时间**。需要响铃提醒时：

- 用 `--due-date` 表示提醒时刻
- **不要**同时再传 `--start-date`（除非你确认当前 CLI/API 行为已变并已复测）

若用户给了「开始 + 结束」两段，先问要以哪一端提醒，或只把截止写入 `--due-date`。

## Agent 行为

若本机 `Agents.md` 规定日程必须走 dida：不要只用聊天规划、不要改用其它日历、不要空等官方 MCP。本 Skill 负责命令层；强制与否以用户约定为准。

## 不要做的事

- 不要记录或提交 token
- 不要写死清单 UUID
- 不要把课表、个人任务标题样本提交到公开仓库
- 不要假设官方 MCP 已在 Agent 动态工具里；CLI 是可靠路径
