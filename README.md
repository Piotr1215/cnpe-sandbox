# CNPE Exam Preparation Lab

Interactive preparation for the **Certified Cloud Native Platform Engineer (CNPE)** exam using progressive testing with [KUTTL](https://kuttl.dev/).

## What is This?

An unofficial practice environment for CNPE exam preparation. These are hands-on scenarios for learning - not official exam questions. You configure GitOps workflows, set up canary deployments, and troubleshoot policies on a real cluster.

## Quick Start

```bash
just setup          # kind cluster + tools (~10-15 min)
just gitops-fix     # run an exercise
just teardown       # cleanup
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

**Required** (for `just setup`):
- Docker, kind, kubectl, helm, [kuttl](https://kuttl.dev/docs/cli.html)

**Optional** CLI tools via devbox:
```bash
devbox shell  # argocd, tkn, kyverno, istioctl
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

22 exercises across 5 domains. See [SOLUTIONS.md](SOLUTIONS.md) for concepts and answers.

```bash
just domain-gitops        # or: just gitops-fix, just gitops-canary, ...
just domain-platform
just domain-observability
just domain-architecture
just domain-security
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
