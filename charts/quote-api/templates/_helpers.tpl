{{- define "quote-api.name" -}}
{{- default .Chart.Name .Values.nameOverride }}
{{- end }}

{{- define "quote-api.chart" -}}
{{ include "quote-api.name" . }}-{{ .Chart.Version }}
{{- end }}

{{- define "quote-api.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "quote-api.labels" -}}
helm.sh/chart: {{ include "quote-api.chart" . }}
app.kubernetes.io/name: {{ include "quote-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}



