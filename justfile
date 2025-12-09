set export

# Show available recipes
default:
  just --list

# ==================== Cluster Setup ====================

# Setup CNPE cluster (kind + all tools)
setup:
  ./exercises/setup-cluster.sh

# Teardown CNPE cluster
teardown:
  kind delete cluster --name cnpe

# ==================== Exercises ====================

# List all exercises
list:
  @echo "CNPE Exercises:"
  @find exercises -mindepth 2 -maxdepth 2 -type d -not -name "00-*" | sort | sed 's|exercises/||'

# Helper to run exercise via test runner
[private]
_run domain test:
  ./scripts/run-exercise.sh "{{domain}}/{{test}}"

# ==================== GitOps Domain (25%) ====================

# Run all GitOps exercises
domain-gitops:
  cd exercises/01-gitops-cd && kubectl kuttl test --config kuttl-test.yaml

# Fix broken ArgoCD sync
gitops-fix: (_run "01-gitops-cd" "01-fix-broken-sync")

# Configure Argo Rollouts canary deployment
gitops-canary: (_run "01-gitops-cd" "02-canary-deployment")

# Setup Tekton trigger pipeline
gitops-tekton: (_run "01-gitops-cd" "03-tekton-trigger")

# ArgoCD ApplicationSet environment promotion
gitops-appset: (_run "01-gitops-cd" "04-environment-promotion")

# Blue/Green deployment with Argo Rollouts
gitops-bluegreen: (_run "01-gitops-cd" "05-bluegreen-deployment")

# ==================== Platform APIs Domain (25%) ====================

# Run all Platform APIs exercises
domain-platform:
  cd exercises/02-platform-apis && kubectl kuttl test --config kuttl-test.yaml

# Create platform CRD for self-service
platform-crd: (_run "02-platform-apis" "01-create-platform-crd")

# Add status subresource to CRD
platform-crd-status: (_run "02-platform-apis" "02-crd-status-subresource")

# ==================== Observability Domain (20%) ====================

# Run all Observability exercises
domain-observability:
  cd exercises/03-observability && kubectl kuttl test --config kuttl-test.yaml

# Fix OpenCost cost allocation labels
obs-cost: (_run "03-observability" "01-opencost-allocation")

# Fix broken Grafana dashboard
obs-grafana: (_run "03-observability" "02-fix-grafana-dashboard")

# Fix Prometheus alerting rule
obs-alerting: (_run "03-observability" "03-prometheus-alerting")

# Configure Jaeger tracing for application
obs-tracing: (_run "03-observability" "04-jaeger-tracing")

# ==================== Architecture Domain (15%) ====================

# Run all Architecture exercises
domain-architecture:
  cd exercises/04-architecture && kubectl kuttl test --config kuttl-test.yaml

# Configure NetworkPolicy for multi-tenancy
arch-networkpolicy: (_run "04-architecture" "01-network-policy")

# Configure ResourceQuota and LimitRange
arch-quota: (_run "04-architecture" "02-resource-quota")

# Configure StorageClass for persistent storage
arch-storage: (_run "04-architecture" "03-storage-class")

# ==================== Security Domain (15%) ====================

# Run all Security exercises
domain-security:
  cd exercises/05-security && kubectl kuttl test --config kuttl-test.yaml

# Fix broken Kyverno policy
security-policy: (_run "05-security" "01-fix-broken-policy")

# Troubleshoot RBAC permissions
security-rbac: (_run "05-security" "02-rbac-troubleshoot")

# Apply Pod Security Standards to namespace
security-pss: (_run "05-security" "03-pod-security-standards")

# Enable strict mTLS with Istio
security-mtls: (_run "05-security" "04-istio-mtls")
