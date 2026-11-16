{{- define "cloud-native-api.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cloud-native-api.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "cloud-native-api.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cloud-native-api.labels" -}}
app.kubernetes.io/name: {{ include "cloud-native-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: cloud-native-cicd-kubernetes
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "cloud-native-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cloud-native-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

