# hybrid-ingestion-runner-helm-chart

Helm chart for deploying the Hybrid Ingestion Runner.

## Features

- Hybrid Ingestion Runner deployment
- ServiceMonitor for Prometheus metrics
- PrometheusRules for alerting
- Grafana Dashboard using Grafana Operator
- ECR Registry Helper for AWS authentication
- Optional Argo Workflows integration

## Grafana Dashboard

This chart includes a Grafana dashboard that can be deployed using the [Grafana Operator](https://github.com/grafana/grafana-operator).

### Prerequisites

1. Grafana Operator must be installed in your cluster
2. A Grafana instance must be deployed via the Grafana Operator

### Configuration

Enable the Grafana dashboard in your `values.yaml`:

```yaml
grafanaDashboard:
  enabled: true
  # Namespace where the dashboard will be created (defaults to Release namespace)
  namespace: ""
  # Folder name in Grafana where the dashboard will be placed
  folderName: "Hybrid Ingestion Runner"
  # Instance selector to match the Grafana instance
  # This should match the labels on your Grafana CR
  instanceSelector:
    dashboards: "grafana"
  # Additional labels for the dashboard
  labels: {}
  # Additional annotations for the dashboard
  annotations: {}
  # Allow cross-namespace import
  allowCrossNamespaceImport: false
```

### Instance Selector

The `instanceSelector` field is crucial - it must match the labels on your Grafana CR. For example, if your Grafana instance has the label `dashboards: grafana`, use:

```yaml
instanceSelector:
  dashboards: "grafana"
```

To find the labels on your Grafana instance:

```bash
kubectl get grafana -n <grafana-namespace> -o yaml
```

### Dashboard Features

The dashboard includes the following panels:

- **Agent Status**: Shows if the hybrid ingestion runner pod is up
- **Connection Status**: Shows the connection status to the Collate server
- **Request Rate**: Displays HTTP request rates
- **CPU Usage**: Container CPU usage over time
- **Memory Usage**: Container memory usage over time
- **Pod Status by Phase**: Shows pod status across different phases

### Dashboard Customization

The dashboard JSON is located at `dashboards/hybrid-ingestion-runner-dashboard.json`. You can customize it by:

1. Importing the JSON into Grafana
2. Making your changes in the Grafana UI
3. Exporting the modified JSON
4. Replacing the file in the chart

### Datasource Configuration

The dashboard uses template variables for datasource selection. If you need to map specific datasource names, use the `datasources` configuration:

```yaml
grafanaDashboard:
  enabled: true
  datasources:
    - inputName: "DS_PROMETHEUS"
      datasourceName: "Prometheus"
```