{{/* Chart name, overridable with nameOverride */}}
{{- define "stockpilot.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Release-scoped name used as the prefix of every resource */}}
{{- define "stockpilot.fullname" -}}
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

{{/* Labels put on every resource */}}
{{- define "stockpilot.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ include "stockpilot.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: stockpilot
{{- end }}

{{/*
Labels a Service uses to find its Pods. Call with a dict: (dict "root" . "component" "backend").
A Service with no matching Pod labels gets no endpoints, so these must match the Pod template.
*/}}
{{- define "stockpilot.selectorLabels" -}}
app.kubernetes.io/name: {{ include "stockpilot.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/* Name of the Secret holding the database password and connection string */}}
{{- define "stockpilot.secretName" -}}
{{- printf "%s-db" (include "stockpilot.fullname" .) }}
{{- end }}

{{/* Imports the image pull secrets, if any */}}
{{- define "stockpilot.imagePullSecrets" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
