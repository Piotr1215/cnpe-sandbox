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
| Policy | Kyverno, Gatekeeper |
| Observability | Prometheus, Grafana |
| Tracing | Jaeger |
| Service Mesh | Istio (ambient mode) |
| Cost | OpenCost |
| Infrastructure | Crossplane |

## Exercises

24 exercises across 5 domains. See [SOLUTIONS.md](SOLUTIONS.md) for concepts and answers.

### 01: GitOps and Continuous Delivery
- **01-fix-broken-sync**: Diagnose and fix an Argo CD application that is out of sync.
- **02-canary-deployment**: Migrate a Kubernetes Deployment to an Argo Rollout for canary releases.
- **03-tekton-trigger**: Troubleshoot a Tekton Trigger that is failing to create PipelineRuns.
- **04-environment-promotion**: Use an Argo CD ApplicationSet to manage an application across multiple environments.
- **05-bluegreen-deployment**: Perform a blue-green deployment using Argo Rollouts.
- **06-istio-canary-release**: Troubleshoot a canary release that is failing due to an Istio misconfiguration.

### 02: Platform APIs and Self-Service
- **01-create-platform-crd**: Create a CustomResourceDefinition to enable self-service environment provisioning.
- **02-crd-status-subresource**: Add a status subresource to a CustomResourceDefinition.
- **03-operator-troubleshoot**: Troubleshoot a Kubernetes operator that is not reconciling.
- **04-self-service-workflow**: Create a self-service workflow using Crossplane.

### 03: Observability and Operations
- **01-opencost-allocation**: Configure OpenCost for cost allocation.
- **02-fix-grafana-dashboard**: Troubleshoot a broken Grafana dashboard.
- **03-prometheus-alerting**: Create a Prometheus alerting rule.
- **04-jaeger-tracing**: Trace a request through a microservices application using Jaeger.
- **05-incident-diagnosis**: Diagnose and fix a failing application using observability tools.

### 04: Platform Architecture
- **01-network-policy**: Configure NetworkPolicies for a multi-tenant environment.
- **02-resource-quota**: Configure ResourceQuotas and LimitRanges for a multi-tenant environment.
- **03-storage-class**: Configure a StorageClass for stateful workloads.
- **04-service-mesh**: Configure Istio for traffic splitting.

### 05: Security and Policy Enforcement
- **01-fix-broken-policy**: Troubleshoot a broken Kyverno policy.
- **02-rbac-troubleshoot**: Troubleshoot an RBAC issue.
- **03-pod-security-standards**: Enforce Pod Security Standards.
- **04-istio-mtls**: Configure strict mTLS with Istio.
- **05-gatekeeper-constraint**: Create a Gatekeeper Constraint to enforce a policy.

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
