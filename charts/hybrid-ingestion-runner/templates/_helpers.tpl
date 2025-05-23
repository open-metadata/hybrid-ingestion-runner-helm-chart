{{/*
Expand the name of the chart.
*/}}
{{- define "hybrid-ingestion-runner.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Expand the namespace.
*/}}
{{- define "hybrid-ingestion-runner.namespace" -}}
{{- if .Values.namespaceOverride }}
{{- .Values.namespaceOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $namespace := .Release.Namespace }}
{{- $namespace | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "hybrid-ingestion-runner.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "hybrid-ingestion-runner.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "hybrid-ingestion-runner.labels" -}}
helm.sh/chart: {{ include "hybrid-ingestion-runner.chart" . }}
{{ include "hybrid-ingestion-runner.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "hybrid-ingestion-runner.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hybrid-ingestion-runner.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use by the Hybrid Runner
*/}}
{{- define "hybrid-ingestion-runner.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "hybrid-ingestion-runner.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use by the Ingestion pods
*/}}
{{- define "hybrid-ingestion-runner.ingestionServiceAccountName" -}}
{{- if .Values.config.ingestionPods.serviceAccount.create }}
{{- default (printf "%s-ingestion" (include "hybrid-ingestion-runner.fullname" .)) .Values.config.ingestionPods.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.config.ingestionPods.serviceAccount.name }}
{{- end }}
{{- end }}
