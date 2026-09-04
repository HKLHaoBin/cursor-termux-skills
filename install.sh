#!/usr/bin/env bash
# Bootstrap Cursor Agent CLI on Termux (Android aarch64).
# Safe to re-run. Does not open a browser or run `agent login`.
set -euo pipefail

REPO_NAME="cursor-termux-skills"
REPO_OWNER="HKLHaoBin"
ZIP_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/main.zip"
HOME="${HOME:-/data/data/com.termux/files/home}"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
REPO_DIR="${HOME}/${REPO_NAME}"
export DEBIAN_FRONTEND=noninteractive
export PATH="${HOME}/.local/bin:${PREFIX}/bin:${PATH:-/usr/bin}"

step() { printf '\n==> %s\n' "$*"; }
ok() { printf 'ok  %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

require_termux() {
  if [[ ! -d /data/data/com.termux/files/usr ]] && [[ "${PREFIX}" != /data/data/com.termux/files/usr* ]]; then
    die "请在 Termux 里运行（F-Droid 版 com.termux）。当前 PREFIX=${PREFIX}"
  fi
  local arch
  arch="$(uname -m)"
  [[ "$arch" == "aarch64" || "$arch" == "arm64" ]] || die "需要 ARM64（uname -m 得到 ${arch}）。"
  ok "Termux ARM64  PREFIX=${PREFIX}"
}

wait_for_apt() {
  local i pid
  for i in $(seq 1 60); do
    pid="$(pgrep -x apt || true)"
    pid="${pid:-$(pgrep -x apt-get || true)}"
    pid="${pid:-$(pgrep -x dpkg || true)}"
    if [[ -z "$pid" ]]; then
      return 0
    fi
    printf '等待 apt/dpkg 结束（pid %s）…\n' "$(echo "$pid" | tr '\n' ' ')"
    sleep 2
  done
  echo "仍有 apt/dpkg 占用锁。请等另一个 Termux 会话结束，或把下面输出交给 Agent：" >&2
  ps aux 2>/dev/null | grep -E '[a]pt|[d]pkg' >&2 || true
  die "未抢锁（默认不 kill 其它 apt 进程）"
}

write_sources() {
  local url="$1"
  mkdir -p "${PREFIX}/etc/apt"
  printf 'deb %s stable main\n' "$url" >"${PREFIX}/etc/apt/sources.list"
}

try_pkg_update() {
  wait_for_apt
  pkg update -y || return 1
}

ensure_pkg_network() {
  step "配置包管理器（非交互）"
  mkdir -p "${PREFIX}/etc/apt" "${PREFIX}/etc/tls/certs"
  if try_pkg_update; then
    ok "pkg update 成功"
    return 0
  fi

  printf 'nameserver 8.8.8.8\nnameserver 1.1.1.1\n' >"${PREFIX}/etc/resolv.conf" || true

  local url
  for url in \
    "https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main" \
    "https://mirrors.ustc.edu.cn/termux/termux-main" \
    "https://packages.termux.dev/apt/termux-main" \
    "https://termux.librehat.com/apt/termux-main"; do
    step "尝试镜像 ${url}"
    write_sources "$url"
    if try_pkg_update; then
      ok "使用镜像 ${url}"
      return 0
    fi
  done

  echo "所有 Termux 镜像都不可用。请核对手机网络、系统时间、DNS，换 Wi-Fi 后再跑本脚本。" >&2
  echo "自检： ping -c 3 8.8.8.8 ; ping -c 3 baidu.com ; date" >&2
  die "pkg update 失败"
}

apt_install() {
  wait_for_apt
  DEBIAN_FRONTEND=noninteractive apt-get \
    -o Dpkg::Options::="--force-confold" \
    -o Dpkg::Options::="--force-confdef" \
    -y --fix-broken install "$@"
}

ensure_dpkg_ok() {
  wait_for_apt
  DEBIAN_FRONTEND=noninteractive dpkg --configure -a || true
}

install_packages() {
  step "安装依赖"
  ensure_dpkg_ok
  apt_install git curl tar python make clang pkg-config binutils openssl-tool ripgrep proot nodejs-lts
  command -v node >/dev/null || die "nodejs-lts 安装后仍没有 node"
  command -v npm >/dev/null || die "nodejs-lts 安装后仍没有 npm"
  command -v proot >/dev/null || die "proot 未装上"
  ok "node $(node -v)  npm $(npm -v)"
}

detect_local_repo() {
  local here src
  src="${BASH_SOURCE[0]:-}"
  if [[ -n "$src" && -f "$src" ]]; then
    here="$(cd "$(dirname "$src")" && pwd)"
    if [[ -f "${here}/skills/cursor-agent-termux/scripts/cursor-agent-proot" ]]; then
      REPO_DIR="$here"
      ok "使用本地仓库 ${REPO_DIR}"
      return 0
    fi
  fi
  return 1
}

fetch_repo() {
  if detect_local_repo; then
    if [[ -d "${REPO_DIR}/.git" ]] && command -v git >/dev/null; then
      git -C "${REPO_DIR}" pull --ff-only origin main 2>/dev/null || true
    fi
    return 0
  fi

  step "获取 ${REPO_NAME}"
  if [[ -d "${REPO_DIR}/.git" ]] && command -v git >/dev/null; then
    git -C "${REPO_DIR}" pull --ff-only origin main || true
    [[ -f "${REPO_DIR}/skills/cursor-agent-termux/scripts/cursor-agent-proot" ]] && return 0
  fi

  local tmp zip top
  tmp="$(mktemp -d)"
  zip="${tmp}/repo.zip"
  curl -fL --retry 3 -o "$zip" "$ZIP_URL" || die "无法下载仓库 ZIP（GitHub 是否可访问？） ${ZIP_URL}"
  unzip -q -o "$zip" -d "$tmp"
  top="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  [[ -n "$top" && -f "${top}/skills/cursor-agent-termux/scripts/cursor-agent-proot" ]] || die "ZIP 布局不符合预期"
  mkdir -p "$(dirname "$REPO_DIR")"
  rm -rf "${REPO_DIR}.new"
  mv "$top" "${REPO_DIR}.new"
  rm -rf "$REPO_DIR"
  mv "${REPO_DIR}.new" "$REPO_DIR"
  rm -rf "$tmp"
  ok "仓库在 ${REPO_DIR}"
}

ensure_shell_env() {
  step "写入 PATH 与 TMPDIR"
  mkdir -p "${HOME}/.local/bin" "${HOME}/.cursor/skills" "${PREFIX}/tmp" "${HOME}/tmp"
  touch "${HOME}/.bashrc"
  export TMPDIR="${PREFIX}/tmp"
  export TMP="${PREFIX}/tmp"
  export TEMP="${PREFIX}/tmp"
  export PATH="${HOME}/.local/bin:${PATH}"

  if ! grep -q 'HOME/.local/bin' "${HOME}/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >>"${HOME}/.bashrc"
  fi
  if ! grep -q 'cursor-termux-skills env' "${HOME}/.bashrc" 2>/dev/null; then
    cat >>"${HOME}/.bashrc" <<'EOF'
# cursor-termux-skills env
export TMPDIR="${PREFIX}/tmp"
export TMP="${PREFIX}/tmp"
export TEMP="${PREFIX}/tmp"
mkdir -p "$TMPDIR" 2>/dev/null || true
# end cursor-termux-skills env
EOF
  fi
  ok "TMPDIR=${TMPDIR}"
}

install_cursor_cli() {
  step "安装 cursor-termux（不用官方 linux glibc node）"
  npm install -g cursor-termux
  command -v cursor-termux >/dev/null || die "cursor-termux 未进入 PATH"
  cursor-termux
  [[ -x "${HOME}/.local/bin/cursor-agent" ]] || die "缺少 ~/.local/bin/cursor-agent"
  [[ -f "${HOME}/.local/share/cursor-agent/termux-preload.js" ]] || die "缺少 termux-preload.js；cursor-termux 可能失败"
  ok "cursor-agent 已安装"
}

rebuild_natives() {
  local script
  script="${REPO_DIR}/skills/cursor-agent-termux-install/scripts/rebuild-termux-natives"
  [[ -f "$script" ]] || die "缺少 ${script}"
  chmod +x "$script"
  step "编译 tree-sitter 原生模块（可能要几分钟，请勿让手机休眠）"
  bash "$script"
}

install_proot_wrapper() {
  local src dest
  src="${REPO_DIR}/skills/cursor-agent-termux/scripts/cursor-agent-proot"
  dest="${HOME}/.local/bin/cursor-agent-proot"
  [[ -f "$src" ]] || die "缺少 ${src}"
  cp "$src" "$dest"
  chmod 755 "$dest"
  if [[ -e "${HOME}/.local/bin/agent" && ! -L "${HOME}/.local/bin/agent" ]]; then
    mv -f "${HOME}/.local/bin/agent" "${HOME}/.local/bin/agent.official.bak"
    ok "已备份官方 agent -> ~/.local/bin/agent.official.bak"
  fi
  ln -sfn "$dest" "${HOME}/.local/bin/agent"
  hash -r 2>/dev/null || true
  ok "agent -> cursor-agent-proot"
}

copy_skills() {
  step "安装 Cursor skills"
  mkdir -p "${HOME}/.cursor/skills"
  cp -R "${REPO_DIR}/skills/"* "${HOME}/.cursor/skills/"
  ok "skills -> ${HOME}/.cursor/skills"
}

merge_cli_config() {
  local cfg="${HOME}/.cursor/cli-config.json"
  mkdir -p "${HOME}/.cursor"
  node - "$cfg" <<'NODE'
const fs = require("fs");
const path = process.argv[2];
let j = {};
try {
  j = JSON.parse(fs.readFileSync(path, "utf8"));
} catch {
  j = {};
}
if (typeof j !== "object" || j === null || Array.isArray(j)) j = {};
j.permissions = j.permissions && typeof j.permissions === "object" ? j.permissions : {};
const allow = Array.isArray(j.permissions.allow) ? j.permissions.allow : [];
if (!allow.includes("Shell(**)")) allow.push("Shell(**)");
j.permissions.allow = allow;
if (!Array.isArray(j.permissions.deny)) j.permissions.deny = [];
fs.writeFileSync(path, JSON.stringify(j, null, 2) + "\n");
NODE
  ok "cli-config 含 Shell(**)"
}

self_check() {
  step "自检"
  touch "${PREFIX}/tmp/.cursor-termux-write-test" || die "${PREFIX}/tmp 不可写"
  rm -f "${PREFIX}/tmp/.cursor-termux-write-test"
  local agent_bin
  agent_bin="$(command -v agent || true)"
  [[ "$agent_bin" == "${HOME}/.local/bin/agent" ]] || die "PATH 上的 agent 是 ${agent_bin:-缺失}，应为 ${HOME}/.local/bin/agent"
  head -n 25 "${HOME}/.local/bin/cursor-agent" | grep -q 'termux-preload.js' || die "cursor-agent 未加载 termux-preload.js"
  if ! head -n 8 "$agent_bin" | grep -q 'cursor-agent-proot\|proot'; then
    # symlink target
    readlink "$agent_bin" | grep -q cursor-agent-proot || die "agent 未指向 cursor-agent-proot"
  fi
  local help
  help="$(agent --help 2>&1)" || {
    printf '%s\n' "$help" >&2
    die "agent --help 失败"
  }
  printf '%s\n' "$help" | grep -qi 'Usage' || {
    printf '%s\n' "$help" >&2
    die "agent --help 没有 Usage"
  }
  ok "agent --help 通过"
}

print_login_hint() {
  cat <<EOF

安装完成。请在本机浏览器登录（脚本不会打开浏览器、也不会代你登录）：

  source ~/.bashrc
  NO_OPEN_BROWSER=1 agent login
  agent status

把打印的 URL 粘到系统浏览器完成授权后即可使用：

  cd ~ && agent

EOF
}

main() {
  require_termux
  ensure_pkg_network
  install_packages
  fetch_repo
  ensure_shell_env
  install_cursor_cli
  rebuild_natives
  install_proot_wrapper
  copy_skills
  merge_cli_config
  self_check
  print_login_hint
}

main "$@"
