{{/* Return the full name of the release */}}
{{- define "sentiment-app-chart.fullname" -}}
{{ .Release.Name }}-sentiment-app-chart
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "sentiment-app-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Name of the chart
*/}}
{{- define "sentiment-app-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sentiment-app-chart.labels" -}}
helm.sh/chart: {{ include "sentiment-app-chart.chart" . }}
{{ include "sentiment-app-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "sentiment-app-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sentiment-app-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}