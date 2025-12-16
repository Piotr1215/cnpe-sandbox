#!/usr/bin/env bash
set -euo pipefail

OS=$(uname -s || echo unknown)

usage() {
  cat <<'EOF'
Usage: install-cli.sh [--apply|--print] [--force]

Options:
  --apply   On Linux, execute recommended install commands with sudo
  --print   On Linux, print recommended install commands (default)
  --force   Reinstall/overwrite even if tools already present (macOS brew; Linux apply mode downloads again)

Notes:
  - macOS always installs via Homebrew (requires brew)
  - For Linux, architecture defaults to x86_64; adjust URLs for arm64
EOF
}

MODE="print"
FORCE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) MODE="apply"; shift ;;
    --print) MODE="print"; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ "$OS" == "Darwin" ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required on macOS. Install: https://brew.sh" >&2
    exit 1
  fi
  echo "Installing CLIs via Homebrew..."
  FORMULAE=(kuttl kind kubernetes-cli helm istioctl tektoncd-cli argocd kyverno yq)
  for f in "${FORMULAE[@]}"; do
    if brew list --formula "$f" >/dev/null 2>&1; then
      if [[ $FORCE -eq 1 ]]; then
        echo "  ↻ Reinstalling $f"
        brew reinstall "$f" || brew install "$f"
      else
        echo "  ✓ $f already installed"
      fi
    else
      brew install "$f"
    fi
  done
  echo ""
  echo "If KUTTL isn't found as a kubectl plugin, ensure PATH is updated."
  echo "Verify with: just check"
elif [[ "$OS" == "Linux" ]]; then
  # Detect distribution
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
  fi
  DISTRO=${ID_LIKE:-${ID:-unknown}}
  if [[ "$MODE" == "print" ]]; then
    echo "Linux detected ($DISTRO). Printing recommended install commands:"
    echo ""
  fi
  case "$DISTRO" in
    *debian*|*ubuntu*)
      if [[ "$MODE" == "print" ]]; then
        cat <<'DEB'
# Debian/Ubuntu
sudo apt-get update && sudo apt-get install -y curl git python3 python3-pip

# kubectl (latest stable)
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
  && chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# kind
curl -Lo kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64 \
  && chmod +x kind && sudo mv kind /usr/local/bin/

# helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# kuttl (CLI)
curl -L https://github.com/kudobuilder/kuttl/releases/download/v0.24.0/kuttl_0.24.0_linux_x86_64.tar.gz | \
  tar -xz kuttl && sudo mv kuttl /usr/local/bin/

# istioctl
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.28.0 sh -
sudo mv istio-1.28.0/bin/istioctl /usr/local/bin/

# tekton CLI (tkn)
curl -LO https://github.com/tektoncd/cli/releases/download/v0.43.0/tkn_0.43.0_Linux_x86_64.tar.gz \
  && tar -xzf tkn_0.43.0_Linux_x86_64.tar.gz tkn && sudo mv tkn /usr/local/bin/ && rm -f tkn_0.43.0_Linux_x86_64.tar.gz

# argocd
curl -sLO https://github.com/argoproj/argo-cd/releases/download/v2.12.3/argocd-linux-amd64 \
  && chmod +x argocd-linux-amd64 && sudo mv argocd-linux-amd64 /usr/local/bin/argocd

# kyverno CLI
curl -LO https://github.com/kyverno/kyverno/releases/download/v1.16.1/kyverno-cli_v1.16.1_linux_x86_64.tar.gz \
  && tar -xzf kyverno-cli_v1.16.1_linux_x86_64.tar.gz kyverno && sudo mv kyverno /usr/local/bin/ && rm -f kyverno-cli_v1.16.1_linux_x86_64.tar.gz

# yq
sudo snap install yq || sudo apt-get install -y yq || echo "Install yq manually if needed"

# Verify
just check
DEB
      else
        # Apply on Debian/Ubuntu
        set -x
        sudo apt-get update
        sudo apt-get install -y curl git python3 python3-pip
        curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl && sudo mv kubectl /usr/local/bin/
        curl -Lo kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
        chmod +x kind && sudo mv kind /usr/local/bin/
        curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        curl -L https://github.com/kudobuilder/kuttl/releases/download/v0.24.0/kuttl_0.24.0_linux_x86_64.tar.gz | tar -xz kuttl
        sudo mv kuttl /usr/local/bin/
        curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.28.0 sh -
        sudo mv istio-1.28.0/bin/istioctl /usr/local/bin/
        curl -LO https://github.com/tektoncd/cli/releases/download/v0.43.0/tkn_0.43.0_Linux_x86_64.tar.gz
        tar -xzf tkn_0.43.0_Linux_x86_64.tar.gz tkn && sudo mv tkn /usr/local/bin/ && rm -f tkn_0.43.0_Linux_x86_64.tar.gz
        curl -sLO https://github.com/argoproj/argo-cd/releases/download/v2.12.3/argocd-linux-amd64
        chmod +x argocd-linux-amd64 && sudo mv argocd-linux-amd64 /usr/local/bin/argocd
        curl -LO https://github.com/kyverno/kyverno/releases/download/v1.16.1/kyverno-cli_v1.16.1_linux_x86_64.tar.gz
        tar -xzf kyverno-cli_v1.16.1_linux_x86_64.tar.gz kyverno && sudo mv kyverno /usr/local/bin/ && rm -f kyverno-cli_v1.16.1_linux_x86_64.tar.gz
        if command -v snap >/dev/null 2>&1; then sudo snap install yq || true; else sudo apt-get install -y yq || true; fi
        set +x
        echo ""
        echo "Done. Run: just check"
      fi
      ;;
    *rhel*|*centos*|*fedora*)
      if [[ "$MODE" == "print" ]]; then
        cat <<'RPM'
# RHEL/CentOS/Fedora (requires sudo)
sudo dnf install -y curl git python3 python3-pip || sudo yum install -y curl git python3 python3-pip

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
  && chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# kind
curl -Lo kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64 \
  && chmod +x kind && sudo mv kind /usr/local/bin/

# helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# kuttl (CLI)
curl -L https://github.com/kudobuilder/kuttl/releases/download/v0.24.0/kuttl_0.24.0_linux_x86_64.tar.gz | \
  tar -xz kuttl && sudo mv kuttl /usr/local/bin/

# istioctl
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.28.0 sh -
sudo mv istio-1.28.0/bin/istioctl /usr/local/bin/

# tekton CLI (tkn)
curl -LO https://github.com/tektoncd/cli/releases/download/v0.43.0/tkn_0.43.0_Linux_x86_64.tar.gz \
  && tar -xzf tkn_0.43.0_Linux_x86_64.tar.gz tkn && sudo mv tkn /usr/local/bin/ && rm -f tkn_0.43.0_Linux_x86_64.tar.gz

# argocd
curl -sLO https://github.com/argoproj/argo-cd/releases/download/v2.12.3/argocd-linux-amd64 \
  && chmod +x argocd-linux-amd64 && sudo mv argocd-linux-amd64 /usr/local/bin/argocd

# kyverno CLI
curl -LO https://github.com/kyverno/kyverno/releases/download/v1.16.1/kyverno-cli_v1.16.1_linux_x86_64.tar.gz \
  && tar -xzf kyverno-cli_v1.16.1_linux_x86_64.tar.gz kyverno && sudo mv kyverno /usr/local/bin/ && rm -f kyverno-cli_v1.16.1_linux_x86_64.tar.gz

# yq
sudo dnf install -y yq || sudo yum install -y yq || echo "Install yq manually if needed"

# Verify
just check
RPM
      else
        # Apply on RHEL/CentOS/Fedora
        set -x
        (sudo dnf install -y curl git python3 python3-pip || sudo yum install -y curl git python3 python3-pip)
        curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl && sudo mv kubectl /usr/local/bin/
        curl -Lo kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
        chmod +x kind && sudo mv kind /usr/local/bin/
        curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        curl -L https://github.com/kudobuilder/kuttl/releases/download/v0.24.0/kuttl_0.24.0_linux_x86_64.tar.gz | tar -xz kuttl
        sudo mv kuttl /usr/local/bin/
        curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.28.0 sh -
        sudo mv istio-1.28.0/bin/istioctl /usr/local/bin/
        curl -LO https://github.com/tektoncd/cli/releases/download/v0.43.0/tkn_0.43.0_Linux_x86_64.tar.gz
        tar -xzf tkn_0.43.0_Linux_x86_64.tar.gz tkn && sudo mv tkn /usr/local/bin/ && rm -f tkn_0.43.0_Linux_x86_64.tar.gz
        curl -sLO https://github.com/argoproj/argo-cd/releases/download/v2.12.3/argocd-linux-amd64
        chmod +x argocd-linux-amd64 && sudo mv argocd-linux-amd64 /usr/local/bin/argocd
        curl -LO https://github.com/kyverno/kyverno/releases/download/v1.16.1/kyverno-cli_v1.16.1_linux_x86_64.tar.gz
        tar -xzf kyverno-cli_v1.16.1_linux_x86_64.tar.gz kyverno && sudo mv kyverno /usr/local/bin/ && rm -f kyverno-cli_v1.16.1_linux_x86_64.tar.gz
        (sudo dnf install -y yq || sudo yum install -y yq) || true
        set +x
        echo ""
        echo "Done. Run: just check"
      fi
      ;;
    *)
      if [[ "$MODE" == "print" ]]; then
        cat <<'GEN'
# Generic Linux
# Consider using devbox for portable CLIs:
#   devbox shell  # adds argocd, tkn, kyverno, istioctl

# Otherwise install from official releases (examples use x86_64):
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
  && chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# kind
curl -Lo kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64 \
  && chmod +x kind && sudo mv kind /usr/local/bin/

# helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# kuttl
curl -L https://github.com/kudobuilder/kuttl/releases/download/v0.24.0/kuttl_0.24.0_linux_x86_64.tar.gz | \
  tar -xz kuttl && sudo mv kuttl /usr/local/bin/

# istioctl
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.28.0 sh -
sudo mv istio-1.28.0/bin/istioctl /usr/local/bin/

# tkn
curl -LO https://github.com/tektoncd/cli/releases/download/v0.43.0/tkn_0.43.0_Linux_x86_64.tar.gz \
  && tar -xzf tkn_0.43.0_Linux_x86_64.tar.gz tkn && sudo mv tkn /usr/local/bin/ && rm -f tkn_0.43.0_Linux_x86_64.tar.gz

# argocd
curl -sLO https://github.com/argoproj/argo-cd/releases/download/v2.12.3/argocd-linux-amd64 \
  && chmod +x argocd-linux-amd64 && sudo mv argocd-linux-amd64 /usr/local/bin/argocd

# kyverno CLI
curl -LO https://github.com/kyverno/kyverno/releases/download/v1.16.1/kyverno-cli_v1.16.1_linux_x86_64.tar.gz \
  && tar -xzf kyverno-cli_v1.16.1_linux_x86_64.tar.gz kyverno && sudo mv kyverno /usr/local/bin/ && rm -f kyverno-cli_v1.16.1_linux_x86_64.tar.gz

# yq (static binary)
curl -Lo yq https://github.com/mikefarah/yq/releases/download/v4.50.1/yq_linux_amd64 \
  && chmod +x yq && sudo mv yq /usr/local/bin/

# Verify
just check
GEN
      else
        echo "Automatic installation for this distro is not supported."
        echo "Please run the printed commands from README or use 'devbox shell'."
        exit 1
      fi
      ;;
  esac
  echo ""
  echo "Note: Commands above assume x86_64 binaries; adjust for arm64 if needed."
  echo "Alternatively, run 'devbox shell' for portable CLIs."
else
  echo "Non-macOS/Linux detected ($OS). Please install CLIs per README 'CLI Install' section."
  echo "Tip: devbox shell provides argocd, tkn, kyverno, istioctl on PATH."
fi
