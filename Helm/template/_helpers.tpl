{{/*
Define Fully Qualified App Name
*/}}
{{- define "app.fullname" }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a partial template to be embedded in other templates
*/}}
{{- define "app.description" }}
{{- printf "Release name: %s" .Release.Name }}
{{- end} }


{{/* 
Render imagePullSecrets 
*/}}
{{- define "app.imagePullSecrets" }}
{{- if .Values.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}


{{/*
Postgres DSN (sqlalchemy asyncpg driver).
*/}}
{{- define "app.dbUrl" }}
{{- printf "postgresql+asyncpg://%s:%s@%s-postgres:5432/%s" .context.Values.appEnv.DB_USER .context.Values.appEnv.DB_PASSWORD (include "app.fullname" .context) .db }}
{{- end }}
