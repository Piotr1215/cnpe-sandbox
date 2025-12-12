#!/usr/bin/env bash
set -eo pipefail

CLUSTER_NAME="cnpe"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if cluster exists
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster ${CLUSTER_NAME} already exists"
  kubectl config use-context "kind-${CLUSTER_NAME}"
  exit 0
fi

echo "=== CNPE Lab Cluster Setup ==="
echo "Estimated time: ~10-15 minutes"
echo ""

# ============ PHASE 1 ============
echo "[1/4] Creating kind cluster..."
echo "      3 nodes (1 control-plane, 2 workers)"
echo "      Ports: 8080→80, 8443→443, 30000-30001"
kind create cluster --name "${CLUSTER_NAME}" --config "${SCRIPT_DIR}/kind-config.yaml"
echo "      ✓ Cluster created"

# ============ PHASE 2 ============
echo ""
echo -n "[2/4] Adding helm repos... 0/7"

# Sequential - counter works
count=0
add_repo() {
  helm repo add "$1" "$2" --force-update >/dev/null 2>&1
  count=$((count + 1))
  echo -ne "\r[2/4] Adding helm repos... ${count}/7"
}
add_repo argo https://argoproj.github.io/argo-helm
add_repo kyverno https://kyverno.github.io/kyverno/
add_repo prometheus-community https://prometheus-community.github.io/helm-charts
add_repo jaegertracing https://jaegertracing.github.io/helm-charts
add_repo opencost https://opencost.github.io/opencost-helm-chart
add_repo istio https://istio-release.storage.googleapis.com/charts
add_repo crossplane-stable https://charts.crossplane.io/stable

helm repo update >/dev/null 2>&1
echo -e "\r[2/4] Adding helm repos... ✓ done    "

# ============ PHASE 3 ============
echo ""
echo "[3/4] Installing components..."

# Check if component is installed
is_installed() {
  local name="$1" ns="$2" check="$3"
  if [[ "$check" == "helm" ]]; then
    helm status "$name" -n "$ns" >/dev/null 2>&1
  else
    kubectl get ns "$ns" >/dev/null 2>&1
  fi
}

# Count and show installed components
show_progress() {
  local target="$1"
  local count=0
  local status=""

  # Check each component - show all with ✓ for installed
  if is_installed argocd argocd helm; then count=$((count+1)); status+="✓argo,"; else status+="argo,"; fi
  if is_installed argo-rollouts argo-rollouts helm; then count=$((count+1)); status+="✓rollouts,"; else status+="rollouts,"; fi
  if is_installed kyverno kyverno helm; then count=$((count+1)); status+="✓kyverno,"; else status+="kyverno,"; fi
  if is_installed prometheus-stack monitoring helm; then count=$((count+1)); status+="✓prom,"; else status+="prom,"; fi
  if is_installed jaeger jaeger helm; then count=$((count+1)); status+="✓jaeger,"; else status+="jaeger,"; fi
  if is_installed crossplane crossplane-system helm; then count=$((count+1)); status+="✓crossplane,"; else status+="crossplane,"; fi
  if is_installed istio-base istio-system helm; then count=$((count+1)); status+="✓istio,"; else status+="istio,"; fi
  if is_installed tekton tekton-pipelines ns; then count=$((count+1)); status+="✓tekton,"; else status+="tekton,"; fi
  if is_installed istiod istio-system helm; then count=$((count+1)); status+="✓istiod,"; else status+="istiod,"; fi
  if is_installed istio-cni istio-system helm; then count=$((count+1)); status+="✓cni,"; else status+="cni,"; fi
  if is_installed ztunnel istio-system helm; then count=$((count+1)); status+="✓ztunnel,"; else status+="ztunnel,"; fi
  if is_installed opencost opencost helm; then count=$((count+1)); status+="✓opencost"; else status+="opencost"; fi

  printf "\r      %d/12 (%s)          " "$count" "$status"

  [[ $count -ge $target ]]
}

# Batch 1: Independent installs
helm install argocd argo/argo-cd -n argocd --create-namespace >/dev/null 2>&1 &
helm install argo-rollouts argo/argo-rollouts -n argo-rollouts --create-namespace >/dev/null 2>&1 &
helm install kyverno kyverno/kyverno -n kyverno --create-namespace >/dev/null 2>&1 &
helm install prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring --create-namespace >/dev/null 2>&1 &
helm install jaeger jaegertracing/jaeger -n jaeger --create-namespace >/dev/null 2>&1 &
helm install crossplane crossplane-stable/crossplane -n crossplane-system --create-namespace >/dev/null 2>&1 &
helm install istio-base istio/base -n istio-system --create-namespace >/dev/null 2>&1 &
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.65.2/release.yaml >/dev/null 2>&1 &

until show_progress 8; do sleep 2; done
wait

# Batch 2: Depends on istio-base
helm install istiod istio/istiod -n istio-system --set profile=ambient >/dev/null 2>&1 &
helm install istio-cni istio/cni -n istio-system >/dev/null 2>&1 &

until show_progress 10; do sleep 2; done
wait

# Batch 3: Depends on istiod + prometheus
helm install ztunnel istio/ztunnel -n istio-system >/dev/null 2>&1 &
helm upgrade --install opencost opencost/opencost \
  -n opencost --create-namespace \
  --set opencost.prometheus.external.enabled=true \
  --set opencost.prometheus.external.url=http://prometheus-stack-kube-prom-prometheus.monitoring.svc:9090 \
  --set opencost.prometheus.internal.enabled=false >/dev/null 2>&1 &

until show_progress 12; do sleep 2; done
wait
echo ""

# ============ PHASE 4 ============
echo ""
echo "[4/4] Waiting for readiness..."

printf "\r      waiting for argocd..."
kubectl wait --for=condition=Available=True --timeout=300s deployment --all -n argocd >/dev/null 2>&1
echo -e "\r      ✓ argocd ready        "

printf "\r      waiting for kyverno..."
kubectl wait --for=condition=Available=True --timeout=300s deployment --all -n kyverno >/dev/null 2>&1
echo -e "\r      ✓ kyverno ready       "

printf "\r      waiting for tekton..."
kubectl wait --for=condition=Available=True --timeout=180s deployment --all -n tekton-pipelines >/dev/null 2>&1
echo -e "\r      ✓ tekton ready        "

echo ""
echo "=== Cluster ready! ==="
echo ""
echo "Run: just list"
