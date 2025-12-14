# Solution: Implement Self-Service Provisioning Workflow

## Solution (Crossplane v2 Pipeline Mode)

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
# Composition - Uses v2 pipeline mode with function-patch-and-transform
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: database-composition
spec:
  mode: Pipeline
  compositeTypeRef:
    apiVersion: platform.cnpe.io/v1
    kind: XDatabaseRequest
  pipeline:
    - step: patch-and-transform
      functionRef:
        name: function-patch-and-transform
      input:
        apiVersion: pt.fn.crossplane.io/v1beta1
        kind: Resources
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

## Crossplane v2 Changes

**Key differences from v1:**
- Uses `mode: Pipeline` instead of `resources` field
- Functions declared in `pipeline` array (function-patch-and-transform)
- Resources defined in function `input` block
- More flexible and composable than v1 resources

**Why pipeline mode?**
- Functions can transform, validate, and generate resources dynamically
- Multiple functions can be chained in sequence
- Better separation of concerns (composition logic vs resource templates)

## Why This Matters

Self-service provisioning enables:
- **Developer autonomy**: Request resources without tickets
- **Standardization**: Platform controls what gets created
- **Guardrails**: XRD schema enforces valid inputs
- **Abstraction**: Hide infrastructure complexity
- **Composition Functions**: v2 pipeline mode provides powerful resource generation patterns
