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
gitops-promotion: (_run "01-gitops-cd" "04-environment-promotion")

# ==================== Security Domain (15%) ====================

# Run all Security exercises
domain-security:
  cd exercises/05-security && kubectl kuttl test --config kuttl-test.yaml

# Fix broken Kyverno policy
security-policy: (_run "05-security" "01-fix-broken-policy")

# Troubleshoot RBAC permissions
security-rbac: (_run "05-security" "02-rbac-troubleshoot")
