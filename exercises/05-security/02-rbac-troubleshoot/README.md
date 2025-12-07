# RBAC Troubleshooting

**Domain:** Security and Policy Enforcement (15%)
**Competency:** Applying RBAC and Security Controls Across Platform Resources
**Time:** 7 minutes

## Context

A platform team created a ServiceAccount `platform-deployer` that should be able to deploy applications in the `cnpe-rbac-test` namespace. However, deployments are failing with permission denied errors.

## Task

Diagnose and fix the RBAC configuration so `platform-deployer` can create and manage Deployments.

### Phase 1: Fix the RoleBinding

The RoleBinding references the wrong ServiceAccount. Fix it to bind to `platform-deployer`.

### Phase 2: Add Missing Permissions

The Role is missing permissions needed for deployments. Add the ability to create/update/delete Deployments.

### Phase 3: Verify Permissions

Test that the ServiceAccount has the required permissions:
```bash
kubectl auth can-i create deployments \
  --as=system:serviceaccount:cnpe-rbac-test:platform-deployer \
  -n cnpe-rbac-test
# Should return "yes"
```

## Hints

Debug RBAC issues:
```bash
# Check what a ServiceAccount can do
kubectl auth can-i --list \
  --as=system:serviceaccount:cnpe-rbac-test:platform-deployer \
  -n cnpe-rbac-test

# Check RoleBinding details
kubectl describe rolebinding -n cnpe-rbac-test

# Check Role permissions
kubectl describe role -n cnpe-rbac-test
```

## Verification

Each phase is checked automatically. Complete all phases to pass.

## Allowed Documentation

- [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [kubectl auth can-i](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_auth/kubectl_auth_can-i/)
