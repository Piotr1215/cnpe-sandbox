# Enforce Pod Security Standards

**Time:** 7 minutes
**Skills tested:** Pod Security Standards, Security Contexts, Namespace Labels

## Context

The security team requires the `production` namespace to enforce the "restricted" Pod Security Standard. All pods must run as non-root with minimal privileges.

## Task

Configure Pod Security Standards for the `production` namespace:

1. Apply PSS **labels** to enforce restricted mode
2. Create a **compliant deployment** that passes PSS validation
3. Verify the pod runs successfully

## Requirements

**Namespace Labels:**
- `pod-security.kubernetes.io/enforce: restricted`
- `pod-security.kubernetes.io/warn: restricted`
- `pod-security.kubernetes.io/audit: restricted`

**Deployment** (`api-server`):
- Pod security context: `runAsNonRoot: true`, `runAsUser: 1000`
- Seccomp profile: `RuntimeDefault`
- Container security context: `allowPrivilegeEscalation: false`
- Drop all capabilities
- Image: `nginx:1.25`

## Verification

The exercise validates:
1. Namespace has PSS enforce=restricted label
2. Deployment has compliant security context
3. Pod is running successfully

## Allowed Documentation

- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/)
