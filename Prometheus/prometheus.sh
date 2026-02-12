# Apply Prometheus, Grafana using Helm

# set up prometheus on k8s cluster
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

kubectl port-forward svc/<name> <port#>
# name e.g. prometheus-grafana, prometheus-prometheus-prometheus-oper-prometheus
# Grafana UI password = prom-operator

# Prometheus UI
kubectl port-forward svc/prometheus-oper-prometheus 9090



# Monitor an app, e.g. mongodb
# Deploy: app, app exporter, service monitor

# Let prometheus discover the service monitor
# by setting service monitor yml label
# release: prometheus

:'
app exporter on prometheus website
in mongodbExpConfig.yml
incl. 
    exporter app
    service: conn. to the exporter
    service monitor
'
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# show params TB config
helm show values prometheus-community/prometheus-mongodb-exporter > mongodbExpConfig.yml
# In the yml, setup uri, put "release: prometheus" in serviceMonitor.additionalLabels

helm install mongodb-exporter prometheus-community/prometheus-mongodb-exporter -f mongodbExpConfig.yml 