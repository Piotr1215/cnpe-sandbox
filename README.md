# CNPE Exam Preparation Lab

Interactive preparation for the **Certified Cloud Native Platform Engineer (CNPE)** exam using progressive testing with [KUTTL](https://kuttl.dev/).

## What is This?

An unofficial practice environment for CNPE exam preparation. These are hands-on scenarios for learning - not official exam questions. You configure GitOps workflows, set up canary deployments, and troubleshoot policies on a real cluster.

## Quick Start

```bash
# Setup kind cluster with all tools (~10-15 min)
just setup

# List available exercises
just list

# Run an exercise
just gitops-fix

# Teardown when done
just teardown
```

## CNPE Exam Overview

| Aspect | Detail |
|--------|--------|
| Duration | 2 hours (120 min) |
| Tasks | ~17 hands-on tasks |
| Pass Score | 64% |
| Format | Remote Linux desktop, terminal + browser |
| K8s Version | v1.34 |

## Prerequisites

**Local kind cluster** (created by `just setup`):
- Docker
- kind
- kubectl
- helm
- [kuttl](https://kuttl.dev/docs/cli.html)

**CLI tools** (via devbox):
```bash
devbox shell  # activates argocd, tkn, kyverno, istioctl
```

## Installed Components

The setup script installs these exam-relevant tools:

| Category | Tool |
|----------|------|
| GitOps | ArgoCD |
| Progressive Delivery | Argo Rollouts |
| CI/CD | Tekton |
| Policy | Kyverno |
| Observability | Prometheus, Grafana |
| Tracing | Jaeger |
| Service Mesh | Istio (ambient mode) |
| Cost | OpenCost |
| Infrastructure | Crossplane |

## Exercises

### GitOps and Continuous Delivery (25%)

| Exercise | Command | Description |
|----------|---------|-------------|
| Fix Broken Sync | `just gitops-fix` | Debug ArgoCD sync issues |
| Canary Deployment | `just gitops-canary` | Configure Argo Rollouts |
| Tekton Trigger | `just gitops-tekton` | Fix Tekton EventListener |
| Environment Promotion | `just gitops-promotion` | ApplicationSet patterns (TODO) |

### Security and Policy (15%)

| Exercise | Command | Description |
|----------|---------|-------------|
| Fix Broken Policy | `just security-policy` | Debug Kyverno policy |
| RBAC Troubleshoot | `just security-rbac` | Fix Role/RoleBinding |

### Run All Exercises in a Domain

```bash
just domain-gitops     # All GitOps exercises
just domain-security   # All Security exercises
```

## How KUTTL Progressive Testing Works

[KUTTL](https://kuttl.dev/) creates **progressive, multi-step exercises** that simulate real exam scenarios.

### Exercise Structure

```
exercises/01-gitops-cd/01-fix-broken-sync/
├── setup.yaml      # Creates the broken state (runs first)
├── 00-assert.yaml  # Step 1: waits for initial fix
├── 01-assert.yaml  # Step 2: validates additional requirements
├── steps.txt       # Hints (format: "0:First step description")
├── answer.md       # Solution - try without peeking!
└── README.md       # Exercise description, docs links
```

### How It Works

1. **Setup Phase**: KUTTL applies `setup.yaml` to create a broken resource
2. **Assertion Phase**: KUTTL waits for conditions to become true. You fix the issue in another terminal.
3. **Timer**: 7-minute timeout matches exam pace (~17 tasks in 2 hours)
4. **Auto-Cleanup**: Resources deleted automatically when test completes

### During the Exercise

- **Split your terminal**: Run KUTTL in one pane, fix issues in another
- **Use the docs**: Each exercise README links to relevant documentation
- **Check steps.txt**: Hints available if stuck

## Curriculum

Based on the [CNCF CNPE Curriculum](https://training.linuxfoundation.org/certification/certified-cloud-native-platform-engineer-cnpe/):

- GitOps and Continuous Delivery (25%)
- Platform APIs and Self-Service (25%)
- Observability and Operations (20%)
- Platform Architecture (15%)
- Security and Policy Enforcement (15%)
