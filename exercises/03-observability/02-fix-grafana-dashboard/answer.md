# Solution: Fix Broken Grafana Dashboard

## Issue 1: Wrong ConfigMap Label

The Grafana sidecar looks for ConfigMaps with label `grafana_dashboard: "1"`, not `grafana-dashboard: "true"`.

```bash
# Fix the label
kubectl label configmap cnpe-dashboard -n monitoring grafana_dashboard=1
kubectl label configmap cnpe-dashboard -n monitoring grafana-dashboard-
```

## Issue 2: Wrong Datasource UID

The dashboard JSON references `wrong-datasource-uid` but should use `prometheus`.

```bash
# Get the current ConfigMap
kubectl get configmap cnpe-dashboard -n monitoring -o yaml > /tmp/dashboard.yaml

# Edit and replace all occurrences of wrong-datasource-uid with prometheus
sed -i 's/wrong-datasource-uid/prometheus/g' /tmp/dashboard.yaml

# Apply the fix
kubectl apply -f /tmp/dashboard.yaml
```

Or use kubectl patch:

```bash
# Get current JSON, fix it, and patch
JSON=$(kubectl get cm cnpe-dashboard -n monitoring -o jsonpath='{.data.cnpe-dashboard\.json}' | sed 's/wrong-datasource-uid/prometheus/g')
kubectl patch configmap cnpe-dashboard -n monitoring --type=merge -p "{\"data\":{\"cnpe-dashboard.json\":$(echo "$JSON" | jq -Rs .)}}"
```

## Why This Matters

- Grafana sidecars auto-discover dashboards via labels
- Datasource UIDs must match what's configured in Grafana
- kube-prometheus-stack creates a datasource with uid `prometheus`
