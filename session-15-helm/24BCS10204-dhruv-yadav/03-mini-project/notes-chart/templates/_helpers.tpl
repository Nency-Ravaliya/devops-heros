{{/*
Chart name and version, e.g. notes-chart-0.1.0
*/}}
{{- define "notes-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Base name for all objects of a release (kept identical to the course spec:
<release>-deploy, <release>-svc, <release>-config).
*/}}
{{- define "notes-chart.fullname" -}}
{{- .Release.Name | trunc 50 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels - must stay stable between upgrades.
*/}}
{{- define "notes-chart.selectorLabels" -}}
app: {{ .Release.Name }}
{{- end }}

{{/*
Common labels added to every object.
*/}}
{{- define "notes-chart.labels" -}}
{{ include "notes-chart.selectorLabels" . }}
environment: {{ .Values.app.environment }}
helm.sh/chart: {{ include "notes-chart.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
{{- end }}

{{/*
Full image reference.
*/}}
{{- define "notes-chart.image" -}}
{{- printf "%s:%s" .Values.image.repository (.Values.image.tag | toString) }}
{{- end }}
