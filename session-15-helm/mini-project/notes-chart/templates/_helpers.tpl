{{/* Common labels applied to every resource */}}
{{- define "notes-chart.labels" -}}
app: {{ .Release.Name }}
environment: {{ .Values.app.environment }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Selector labels (must never change between upgrades) */}}
{{- define "notes-chart.selectorLabels" -}}
app: {{ .Release.Name }}
{{- end }}
