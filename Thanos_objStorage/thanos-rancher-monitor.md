# Rancher & Thanos Multi-cluster Monitoring

## Ensure `kubectl` pointing to Rancher cluster
```
kubectl create secret generic thanos-objstore-config \
  --from-file=thanos.yml=bucket-config.yml \
  --namespace cattle-monitoring-system
```

1. Rancher -> Apps -> Installed Apps -> rancher-monitoring -> Edit yaml
- Modify `prometheus.prometheusSpec`
```
prometheus:
  prometheusSpec:
    # Thanos needs externalLabels to distinguish a cluster's data from others
    externalLabels:
      cluster: 'rke-rancher'  # Give cluster a unique name
      monitor: 'rancher-monitoring'

    # 2. Enable Thanos Sidecar, i.e. injection
    thanos:   
      blockSize: 3m   
      image: rancher/mirrored-thanos-thanos:v0.37.2

      # Ref the Secret 
      objectStorageConfig:
        existingSecret:
          key: thanos.yml              # The key we used in the kubectl command
          name: thanos-objstore-secret # Secret name
```
2. Upgrade/Save
3. Workloads -> Pods (ns: cattle-monitoring-system)
4. Chk pod logs
5. Select container: `thanos-sidecar`
6. Find logs: `uploaded block` / `msg=successfully loaded prometheus external labels`



## Enable UI on localhost: port forward
```
kubectl port-forward svc/thanos-querier 9090:9090 -n cattle-monitoring-system
```
check `http://localhost:9090/`

## Enable Bucket Web UI
```
kubectl port-forward svc/thanos-bucket-web 8080:8080 -n cattle-monitoring-system
```

## PromQL / Thanos query
```
sum(node_memory_MemAvailable_bytes{cluster="local-cluster"}) by (instance)

max(thanos_objstore_bucket_last_successful_upload_time) # Check Azure Storage upload
```


## Identify diff clusters: externalLabels in 1 blob container
`meta.json` in Azure Storage:
```
"thanos": {
	"labels": {
		"monitor": "rancher-monitoring",
		"replica": "cluster-A" # label
  }
}
```

```
kubectl get secret <secret_name> -o yaml
```