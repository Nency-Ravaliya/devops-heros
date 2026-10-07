{{/* Chart name */}}
{{- define "taskboard.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Fully qualified app name: release name, or release-chart if they differ */}}
{{- define "taskboard.fullname" -}}
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

{{- define "taskboard.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Common labels */}}
{{- define "taskboard.labels" -}}
helm.sh/chart: {{ include "taskboard.chart" . }}
app.kubernetes.io/name: {{ include "taskboard.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: taskboard
{{- end }}

{{/* Selector labels; call with (dict "ctx" . "component" "backend") */}}
{{- define "taskboard.selectorLabels" -}}
app.kubernetes.io/name: {{ include "taskboard.name" .ctx }}
app.kubernetes.io/instance: {{ .ctx.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{- define "taskboard.backendImage" -}}
{{ .Values.backend.image.repository }}:{{ .Values.backend.image.tag | default .Chart.AppVersion }}
{{- end }}
{{- define "taskboard.frontendImage" -}}
{{ .Values.frontend.image.repository }}:{{ .Values.frontend.image.tag | default .Chart.AppVersion }}
{{- end }}

{{- define "taskboard.postgresName" -}}
{{ include "taskboard.fullname" . }}-postgres
{{- end }}

{{- define "taskboard.dbHost" -}}
{{- if .Values.postgres.enabled }}{{ include "taskboard.postgresName" . }}{{ else }}{{ required "postgres.host is required when postgres.enabled=false" .Values.postgres.host }}{{ end }}
{{- end }}

{{- define "taskboard.secretName" -}}
{{- if .Values.postgres.auth.existingSecret }}{{ .Values.postgres.auth.existingSecret }}{{ else }}{{ include "taskboard.fullname" . }}-db{{ end }}
{{- end }}
