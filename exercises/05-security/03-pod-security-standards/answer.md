# Solution: Apply Pod Security Standards

## Phase 1: Apply PSS Labels

```bash
kubectl label namespace production \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/audit=restricted
```

## Phase 2: Fix Deployment Security Context

```bash
kubectl edit deployment api-server -n production
```

Update the pod spec:
```yaml
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: api
          image: nginx:1.25
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: "50m"
              memory: "64Mi"
            limits:
              cpu: "100m"
              memory: "128Mi"
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
```

## Complete One-liner

```bash
kubectl label namespace production \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/audit=restricted --overwrite

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-server
  template:
    metadata:
      labels:
        app: api-server
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: api
          image: nginx:1.25
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: "50m"
              memory: "64Mi"
            limits:
              cpu: "100m"
              memory: "128Mi"
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
EOF
```

## Key Concepts

1. **Pod Security Standards Levels**:
   - `privileged`: Unrestricted (dangerous)
   - `baseline`: Minimally restrictive, prevents known escalations
   - `restricted`: Heavily restricted, security best practices

2. **PSS Label Modes**:
   - `enforce`: Reject non-compliant pods
   - `warn`: Allow but warn
   - `audit`: Log to audit log

3. **Restricted Level Requirements**:
   - runAsNonRoot: true
   - Seccomp profile set
   - No privilege escalation
   - Drop all capabilities
   - No hostPath, hostNetwork, etc.

## Verification Commands

```bash
kubectl get ns production --show-labels
kubectl describe ns production | grep pod-security
kubectl get pods -n production
kubectl auth can-i create pods -n production --as=system:serviceaccount:production:default
```
