# Configure Strict mTLS with Istio

**Time:** 7 minutes
**Skills tested:** Istio Security, mTLS, PeerAuthentication, DestinationRule

## Context

The `payments` namespace handles sensitive financial transactions. The security team requires all service-to-service communication to use mutual TLS encryption.

## Task

Configure strict mTLS for the `payments` namespace:

1. Create a **PeerAuthentication** policy for strict mTLS
2. Create a **DestinationRule** for mTLS traffic policy
3. Deploy a test service and verify mTLS is working

## Requirements

**PeerAuthentication** (`default`):
- Namespace: payments
- mTLS mode: STRICT

**DestinationRule** (`payment-api-mtls`):
- Host: `payment-api.payments.svc.cluster.local`
- TLS mode: ISTIO_MUTUAL

**Test Service** (`payment-api`):
- Deployment with nginx:1.25
- Service on port 80

## Verification

The exercise validates:
1. PeerAuthentication with STRICT mode exists
2. DestinationRule with ISTIO_MUTUAL exists
3. Pod has istio-proxy sidecar injected

## Allowed Documentation

- [Istio mTLS](https://istio.io/latest/docs/concepts/security/#mutual-tls-authentication)
- [PeerAuthentication](https://istio.io/latest/docs/reference/config/security/peer_authentication/)
