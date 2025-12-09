# Solution: Enable Strict mTLS with Istio

## Phase 1: Create PeerAuthentication

```bash
kubectl apply -f - <<'EOF'
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: payments
spec:
  mtls:
    mode: STRICT
EOF
```

## Phase 2: Create DestinationRule

```bash
kubectl apply -f - <<'EOF'
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: payment-api-mtls
  namespace: payments
spec:
  host: payment-api.payments.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
```

## Complete One-liner

```bash
kubectl apply -f - <<'EOF'
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: payments
spec:
  mtls:
    mode: STRICT
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: payment-api-mtls
  namespace: payments
spec:
  host: payment-api.payments.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
```

## Key Concepts

1. **PeerAuthentication**: Controls inbound mTLS
   - `PERMISSIVE`: Accept both plaintext and mTLS
   - `STRICT`: Only accept mTLS
   - `DISABLE`: No mTLS

2. **DestinationRule**: Controls outbound mTLS
   - `DISABLE`: No TLS
   - `SIMPLE`: Originate TLS
   - `MUTUAL`: Client cert required
   - `ISTIO_MUTUAL`: Use Istio-managed certs

3. **Namespace-wide vs Workload-specific**:
   - No selector = applies to all workloads
   - With selector = applies to specific workloads

## Verification

```bash
# Check mTLS status
istioctl x authz check payment-api-xxx -n payments

# Verify PeerAuthentication
kubectl get peerauthentication -n payments

# Test from another pod (should work with sidecar, fail without)
kubectl exec -it sleep-pod -n payments -- curl payment-api.payments:80
```

## Troubleshooting

```bash
# Check if sidecar is injected
kubectl get pods -n payments -o jsonpath='{range .items[*]}{.metadata.name}{": "}{.spec.containers[*].name}{"\n"}{end}'

# Force sidecar injection if missing
kubectl label namespace payments istio-injection=enabled --overwrite
kubectl rollout restart deployment payment-api -n payments
```
