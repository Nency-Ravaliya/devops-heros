{{- define "studytrack.labels" -}}
app.kubernetes.io/name: studytrack
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{- define "studytrack.backendImage" -}}
{{ .Values.image.registry }}/{{ .Values.image.backend }}:{{ .Values.image.tag }}
{{- end }}

{{- define "studytrack.frontendImage" -}}
{{ .Values.image.registry }}/{{ .Values.image.frontend }}:{{ .Values.image.tag }}
{{- end }}

{{- define "studytrack.databaseUrl" -}}
postgresql+psycopg://{{ .Values.postgres.user }}:{{ .Values.postgres.password }}@studytrack-postgres:5432/{{ .Values.postgres.database }}
{{- end }}
