#!/usr/bin/env bash
# Run install.sh inside a fake Termux prefix (for GitHub Actions / local check).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FAKE="$(mktemp -d "${TMPDIR:-/tmp}/cursor-termux-ci.XXXXXX")"
cleanup() { rm -rf "$FAKE"; }
trap cleanup EXIT

export CURSOR_TERMUX_CI=1
export CURSOR_TERMUX_CI_BIN="${ROOT}/tests/ci/bin"
export HOME="${FAKE}/home"
export PREFIX="${FAKE}/usr"
export DEBIAN_FRONTEND=noninteractive

mkdir -p "${HOME}" "${PREFIX}/bin" "${PREFIX}/tmp" "${PREFIX}/var/lib/dpkg" "${PREFIX}/etc/apt"
chmod +x "${ROOT}/tests/ci/bin/"*

# Real node for cli-config merge; mocks first for pkg/npm/proot.
export PATH="${CURSOR_TERMUX_CI_BIN}:${PREFIX}/bin:${HOME}/.local/bin:${PATH}"

echo "CI fake HOME=${HOME}"
echo "CI fake PREFIX=${PREFIX}"

bash -n "${ROOT}/install.sh"
bash -n "${ROOT}/skills/cursor-agent-termux-install/scripts/rebuild-termux-natives"
bash -n "${ROOT}/skills/cursor-agent-termux/scripts/cursor-agent-proot"

set +e
out="$(bash "${ROOT}/install.sh" 2>&1)"
st=$?
set -e
printf '%s\n' "$out"

if [[ "$st" -ne 0 ]]; then
  echo "install.sh exited ${st}" >&2
  exit "$st"
fi

printf '%s\n' "$out" | grep -q '安装完成' || {
  echo "missing login hint" >&2
  exit 1
}
printf '%s\n' "$out" | grep -q 'agent --help 通过' || {
  echo "self_check did not pass agent --help" >&2
  exit 1
}

[[ -L "${HOME}/.local/bin/agent" ]] || { echo "agent is not a symlink" >&2; exit 1; }
readlink "${HOME}/.local/bin/agent" | grep -q cursor-agent-proot || {
  echo "agent does not point at cursor-agent-proot" >&2
  exit 1
}
[[ -f "${HOME}/.cursor/skills/cursor-agent-termux/SKILL.md" ]] || {
  echo "skills not copied" >&2
  exit 1
}
grep -q 'Shell(\*\*)' "${HOME}/.cursor/cli-config.json" || {
  echo "cli-config missing Shell(**)" >&2
  exit 1
}
grep -q 'HOME/.local/bin' "${HOME}/.bashrc" || {
  echo "bashrc missing PATH" >&2
  exit 1
}
[[ -d "${HOME}/.local/share/cursor-agent/versions/ci-test/node_modules/tree-sitter" ]] || {
  echo "tree-sitter native mock not installed" >&2
  exit 1
}

# Resume: second run must skip wiping and still pass.
echo "==> second run (resume)"
bash "${ROOT}/install.sh" >/tmp/install-sh-resume.log
grep -q '跳过' /tmp/install-sh-resume.log || grep -q '已可用' /tmp/install-sh-resume.log || grep -q '缺 native' /tmp/install-sh-resume.log || {
  echo "resume did not skip cursor-termux as expected" >&2
  cat /tmp/install-sh-resume.log >&2
  exit 1
}

echo "CI selftest passed"
