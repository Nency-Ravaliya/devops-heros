{{- define "stockpilot.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Release-scoped prefix; "stockpilot" for the usual release name. */}}
{{- define "stockpilot.fullname" -}}
{{- if contains (include "stockpilot.name" .) .Release.Name -}}
{{- .Release.Name | trunc 50 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "stockpilot.name" .) | trunc 50 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "stockpilot.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app.kubernetes.io/name: {{ include "stockpilot.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ include "stockpilot.tag" . | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Selector labels; call with (list . "backend") */}}
{{- define "stockpilot.selectorLabels" -}}
{{- $ := index . 0 -}}
app.kubernetes.io/name: {{ include "stockpilot.name" $ }}
app.kubernetes.io/instance: {{ $.Release.Name }}
app.kubernetes.io/component: {{ index . 1 }}
{{- end -}}

{{- define "stockpilot.tag" -}}
{{- .Values.image.tag | default .Chart.AppVersion -}}
{{- end -}}

{{/* Image reference; call with (list . "stockpilot-backend") */}}
{{- define "stockpilot.image" -}}
{{- $ := index . 0 -}}
{{- $repo := index . 1 -}}
{{- if $.Values.image.registry -}}
{{- $repo = printf "%s/%s" $.Values.image.registry $repo -}}
{{- end -}}
{{- printf "%s:%s" $repo (include "stockpilot.tag" $) -}}
{{- end -}}

{{- define "stockpilot.secretName" -}}
{{- default (printf "%s-db" (include "stockpilot.fullname" .)) .Values.database.existingSecret -}}
{{- end -}}
