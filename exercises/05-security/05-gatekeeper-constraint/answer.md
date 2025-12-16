## The Solution

To solve this exercise, you need to create a `K8sRequiredLabels` `Constraint` that uses the `K8sRequiredLabels` `ConstraintTemplate` to enforce the policy that all namespaces must have a `team` label.

Here is the YAML for the `Constraint`:

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: ns-must-have-team-label
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Namespace"]
  parameters:
    labels: ["team"]
```

You can apply this `Constraint` with `kubectl apply -f`. Once the `Constraint` is applied, any attempt to create a namespace without the `team` label will be rejected by Gatekeeper.
