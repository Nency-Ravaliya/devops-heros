{{- define "queuedesk.name" -}}
{{- .Release.Name | trunc 45 | trimSuffix "-" -}}
{{- end -}}
{{- define "queuedesk.labels" -}}
app.kubernetes.io/name: queuedesk
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}
