---
name: termux-shizuku
description: >-
  Set up and use Shizuku rish from Termux for ADB-level shell (uid 2000):
  extract rish from the Shizuku APK, RISH_APPLICATION_ID, Android 14+ dex
  chmod 400, prefer rish over adb devices. Use when the user mentions Shizuku,
  rish, ADB, wireless debugging, pm install, or APK parse errors from Termux.
---

# Shizuku rish on Termux

Termux 里 `adb devices` 经常为空（无线调试 TCP 未暴露给 Termux）。需要 ADB 级权限时用 **Shizuku 的 `rish`**，不要死磕 `adb`，也不要在非 root/非 adb uid 下加载 `libshizuku.so`（会 fatal）。

## 前置

1. 设备上安装并启用 [Shizuku](https://github.com/RikkaApps/Shizuku)（无线调试或 root 启动均可）。
2. Termux：`pkg install -y android-tools unzip`（`adb` 可选；`rish` 才是主路径）。

## 安装 rish

从 **Shizuku APK** 的 `assets/` 取出包装脚本与 dex（APK 路径因设备而异，让用户提供或从已安装包导出）：

```bash
# 示例：已有 SHIZUKU_APK 指向 apk 文件
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
unzip -o -j "$SHIZUKU_APK" assets/rish assets/rish_shizuku.dex -d "$PREFIX/bin"
chmod 755 "$PREFIX/bin/rish"
# Android 14+：dex 必须对应用不可随意改写
chmod 400 "$PREFIX/bin/rish_shizuku.dex"
```

在 `rish` 脚本或 Termux 环境中设置：

```bash
export RISH_APPLICATION_ID=com.termux
```

可写入 `.bashrc`。应用 ID 必须是 **Termux 的包名** `com.termux`（若用 Termux 变体，改成实际 applicationId）。

## 验证

```bash
rish -c 'id'
```

期望类似：`uid=2000(shell)`。不是 2000 则 Shizuku 未授权、未启动，或 `RISH_APPLICATION_ID` 不对。

## 用法

```bash
rish -c 'pm list packages | head'
rish          # 交互 shell（uid 2000）
```

能用 `rish` 完成的不要改走 `adb shell`。本机 `adb devices` 空白时这是正常现象，不是「adb 没装」。

## 从 Termux 安装 APK：解析失败

系统安装器打开 Termux **私有目录**里的 APK（权限常为 `600`）时，可能报 **「解析包时出现了问题」**，而不是明确的权限错误。APK 本身可能完好（`unzip -t`、`aapt dump badging` 通过）。

绕过（择一）：

1. 拷到公共下载目录后再用系统安装器打开（需要共享存储权限或 `rish`/`cp` 到 `/sdcard/Download`）。
2. 在 Termux 对 APK 目录起 `python3 -m http.server`，用系统浏览器下载到公共目录再装。
3. Shizuku 可用时：`rish -c 'pm install -r /path/that/shell-user-can-read'`（路径必须是 uid 2000 可读；Termux 家目录通常不行）。

## 不要做的事

- 不要在未授权 Shizuku 时反复 `adb kill-server`
- 不要依赖 `libshizuku.so` 给普通 Termux uid 用
- 不要把用户设备序列号、无线调试配对码写入 MEMORY 或 git
