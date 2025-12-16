#!/usr/bin/env bash
set -euo pipefail

OS=$(uname -s || echo unknown)

if [[ "$OS" == "Darwin" ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required on macOS. Install: https://brew.sh" >&2
    exit 1
  fi
  echo "Updating Homebrew and upgrading CLI tools..."
  brew update || true
  FORMULAE=(kuttl kind kubernetes-cli helm istioctl tektoncd-cli argocd kyverno yq)
  for f in "${FORMULAE[@]}"; do
    echo "  -> Upgrading $f"
    brew upgrade "$f" || true
  done
  brew cleanup -s || true
  echo "\nDone. Run: just check"
else
  echo "Linux or other OS detected ($OS)."
  echo "If you installed via package manager, use your distro's upgrade commands (apt/dnf/yum)."
  echo "If you used this repo's binary installs, re-run: just install-cli --apply [--force]"
  echo "Alternatively, use: devbox shell"
fi

