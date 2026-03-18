# hybrid-ingestion-runner-helm-chart

Helm chart for deploying the Hybrid Ingestion Runner.

## Features

- Hybrid Ingestion Runner deployment
- ServiceMonitor for Prometheus metrics
- PrometheusRules for alerting
- Grafana Dashboard using Grafana Operator
- ECR Registry Helper for AWS authentication
- Optional Argo Workflows integration
- OpenShift / ROSA support

## Installing on OpenShift / ROSA

### Prerequisites

- ROSA or OpenShift cluster with `oc` CLI configured
- Helm 3 installed
- AWS CLI configured with credentials that can authenticate to ECR

### 1. Add the Argo Helm repo and build dependencies

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm dependency build ./charts/hybrid-ingestion-runner
```

### 2. Create the namespace

```bash
oc new-project hybrid-ingestion-runner
```

### 3. Create the ECR pull secret

ECR tokens expire after 12 hours. Create the secret manually using the AWS CLI:

```bash
NAMESPACE="hybrid-ingestion-runner"
AWS_REGION="eu-west-1"
AWS_ACCOUNT="118146679784"
ECR_REGISTRY="${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"

kubectl create secret docker-registry omd-registry-credentials \
  --docker-server="$ECR_REGISTRY" \
  --docker-username=AWS \
  --docker-password="$(aws ecr get-login-password --region $AWS_REGION)" \
  --namespace="$NAMESPACE"
```

To refresh the token before it expires (safe to re-run):

```bash
kubectl create secret docker-registry omd-registry-credentials \
  --docker-server="$ECR_REGISTRY" \
  --docker-username=AWS \
  --docker-password="$(aws ecr get-login-password --region $AWS_REGION)" \
  --namespace="$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 4. Install using the rosa-values.yaml

Edit `rosa-values.yaml` and set your Collate credentials:

```yaml
config:
  agentId: "RemoteRunner"        # unique identifier for this runner
  authToken: "your-auth-token"   # Collate auth token
  serverHost: "your-cluster.getcollate.io"
```

Then install:

```bash
helm upgrade --install hybrid-ingestion-runner \
  ./charts/hybrid-ingestion-runner \
  --namespace hybrid-ingestion-runner \
  -f rosa-values.yaml
```

### OpenShift SCC compatibility

OpenShift's `restricted-v2` SCC rejects pods that set a specific `runAsUser`, `fsGroup`, or `seccompProfile` — it assigns a UID from its own allowed range automatically. Setting `openshift.enabled: true` in your values instructs the chart to omit those fields:

```yaml
openshift:
  enabled: true
```

This causes the deployment to render only the fields that are compatible with `restricted-v2`:

```yaml
# pod level
securityContext:
  runAsNonRoot: true

# container level
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop: [ALL]
  runAsNonRoot: true
```

### ECR Registry Helper on OpenShift

The built-in `ecrRegistryHelper` CronJob uses the `heyvaldemar/aws-kubectl` image which requires root and is blocked by OpenShift SCCs. It is disabled in `rosa-values.yaml`. Refresh the `omd-registry-credentials` secret manually using the command in step 3, or schedule it externally.

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