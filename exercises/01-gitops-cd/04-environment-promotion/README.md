# Create ApplicationSet for Environment Promotion

**Time:** 7 minutes
**Skills tested:** ArgoCD ApplicationSet, List Generator, Multi-environment deployment

## Context

The platform team needs to deploy the `demo-app` application across three environments: dev, staging, and production. Each environment has its own namespace already created. Instead of managing three separate Application resources, you should use an ApplicationSet to generate them automatically.

## Task

Create an ApplicationSet named `demo-app-set` in the `argocd` namespace that:

1. Uses a **List generator** with three elements for dev, staging, and prod
2. Generates Applications named `demo-app-dev`, `demo-app-staging`, `demo-app-prod`
3. Deploys to namespaces `demo-dev`, `demo-staging`, `demo-prod` respectively
4. Uses the guestbook app from `https://github.com/argoproj/argocd-example-apps.git` (path: `guestbook`)
5. Enables automated sync with pruning and self-heal

## Requirements

- Generator must use `elements` array with `env` and `namespace` parameters
- Template must use parameter substitution for name and destination
- All three Applications must be created and syncing

## Verification

The exercise validates:
1. ApplicationSet exists with correct generator
2. Template uses proper parameter substitution
3. All three Applications are created

## Allowed Documentation

- [ArgoCD ApplicationSet](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/)
- [List Generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-List/)
