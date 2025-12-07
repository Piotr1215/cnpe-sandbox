# Solution

## Phase 1: Fix RoleBinding

```bash
kubectl patch rolebinding platform-deployer-binding -n cnpe-rbac-test \
  --type='json' -p='[{"op": "replace", "path": "/subjects/0/name", "value": "platform-deployer"}]'
```

Or edit directly:
```bash
kubectl edit rolebinding platform-deployer-binding -n cnpe-rbac-test
# Change: name: platform-deploy -> name: platform-deployer
```

## Phase 2: Add Deployment Permissions

```bash
kubectl patch role platform-deployer-role -n cnpe-rbac-test \
  --type='json' -p='[{"op": "add", "path": "/rules/-", "value": {"apiGroups": ["apps"], "resources": ["deployments"], "verbs": ["get", "list", "watch", "create", "update", "delete"]}}]'
```

Or edit directly:
```bash
kubectl edit role platform-deployer-role -n cnpe-rbac-test
# Add under rules:
# - apiGroups: ["apps"]
#   resources: ["deployments"]
#   verbs: ["get", "list", "watch", "create", "update", "delete"]
```

## Verify

```bash
kubectl auth can-i create deployments \
  --as=system:serviceaccount:cnpe-rbac-test:platform-deployer \
  -n cnpe-rbac-test
# yes
```
