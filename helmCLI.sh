# Basics
# Template k8s manifests
# `values.yml`
replicaCount: 3
# `deploy.yml`
replicas: {{Values.replicaCount}}

helm install/upgrade/rollback app1

# Chk rendered val
helm get values <release_name> -n <namespace>

# Chart ver
helm ls -n <ns>
helm history <release_name> -n <ns>

# Upgrade custom values
helm upgrade vault <release_name> -n <ns> -f <value-file.yml>

# Rollback
helm rollback <release_name> <revision_ver> -n <ns>
