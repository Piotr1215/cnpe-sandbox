# Solution: Implement Self-Service Provisioning Workflow

## Solution

```bash
kubectl apply -f - <<'EOF'
# XRD - Defines the self-service API
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xdatabaserequests.platform.cnpe.io
spec:
  group: platform.cnpe.io
  names:
    kind: XDatabaseRequest
    plural: xdatabaserequests
  claimNames:
    kind: DatabaseRequest
    plural: databaserequests
  versions:
    - name: v1
      served: true
      referenceable: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                size:
                  type: string
                  enum: [small, medium, large]
                engine:
                  type: string
                  enum: [postgres, mysql]
              required: [size, engine]
---
# Composition - Defines what gets created
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: database-composition
spec:
  compositeTypeRef:
    apiVersion: platform.cnpe.io/v1
    kind: XDatabaseRequest
  resources:
    - name: connection-config
      base:
        apiVersion: kubernetes.crossplane.io/v1alpha2
        kind: Object
        spec:
          forProvider:
            manifest:
              apiVersion: v1
              kind: ConfigMap
              metadata:
                namespace: cnpe-selfservice-test
              data:
                host: "db.internal"
                port: "5432"
---
# Test claim
apiVersion: platform.cnpe.io/v1
kind: DatabaseRequest
metadata:
  name: test-db
  namespace: cnpe-selfservice-test
spec:
  size: small
  engine: postgres
EOF
```

## Why This Matters

Self-service provisioning enables:
- **Developer autonomy**: Request resources without tickets
- **Standardization**: Platform controls what gets created
- **Guardrails**: XRD schema enforces valid inputs
- **Abstraction**: Hide infrastructure complexity
