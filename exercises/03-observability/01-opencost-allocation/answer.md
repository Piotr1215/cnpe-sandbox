# Solution: Fix OpenCost Cost Allocation

## Fastest Method (exam recommended)

### Step 1: Label namespace
```bash
kubectl label ns cnpe-team-alpha cost-center=cc-platform team=alpha environment=dev
```

### Step 2: Label deployment + pod template
```bash
kubectl edit deployment cost-test-app -n cnpe-team-alpha
```

Add labels in two places:
```yaml
metadata:
  labels:
    cost-center: cc-platform   # <-- add here
    team: alpha
    environment: dev
spec:
  template:
    metadata:
      labels:
        app: cost-test
        cost-center: cc-platform   # <-- and here
        team: alpha
        environment: dev
```

Save and exit (`:wq`). Done.

## Alternative: CLI only (no editor)

```bash
# Namespace
kubectl label ns cnpe-team-alpha cost-center=cc-platform team=alpha environment=dev

# Deployment metadata
kubectl label deploy cost-test-app -n cnpe-team-alpha cost-center=cc-platform team=alpha environment=dev

# Pod template (merge patch)
kubectl patch deploy cost-test-app -n cnpe-team-alpha --type=merge -p '
spec:
  template:
    metadata:
      labels:
        cost-center: cc-platform
        team: alpha
        environment: dev
'
```

## Why This Matters

OpenCost aggregates costs by labels via `/allocation` API:
- `aggregate=label:team` - costs by team
- `aggregate=label:cost-center` - costs by cost center

Pod-level labels are essential - that's where resource consumption is measured.
