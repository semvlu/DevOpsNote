kubectl create -f k8s.yml
kubectl get [all, po,...]  # rc: replication controller

# Get #resources
kubectl get all --no-headers | wc -l

# Gen template yml
kubectl run <pod-name> --image=busybox -n <ns> --dry-run=client -o yaml > pod.yml

kubectl create deployment <deploy-name> \
--image=nginx \
--replicas=3 \
--dry-run=client -o yaml > deployment.yml

kubectl delete pod <pod-name> # delete a pod 
kubectl scale --replicas=4 -f k8s.yml # scale #pods

# List all images running in a cluster
kubectl get pods -A -o custom-columns='DATA:spec.containers[*].image'

# List all images running, group by Pod
kubectl get pods -A -o custom-columns='NAME:.metadata.name,IMAGE:.spec.containers[*].image'

# Reference 
kubectl api-resources
kubectl explain <resource-kind> --recursive # Align w/ yaml fields
kubectl explain pod.spec.containers

# Deployment
kubectl set image deploy <deploy-name> \
<pod-name>:<img-path>:<version> # e.g. <img-path>: dockerUsr/repos
# update image of a pod in a deployment

kubectl expose deploy <deploy-name> \
--name=<service-name>
--port=80 \
--target-port=80 \
--type=NodePort 

minikube service <service-name> --url # get service url

kubectl scale deploymenmt --replicas=1 <container> <container>...
# Scale down
--replicas=0
# Each container as a service

# HPA
kubectl autoscale deploy <deploy-name> --min=2 --max=5

# Apply config (declarative)
kubectl apply -f <filepath> # pod/service/deployment/ingress etc. .yml
# Delete config
kubectl delete -f <filepath>

# Secret 
kubectl create secret <type>
kubectl create secret generic <secret> \
--from-literal=<k>=<v> \ 
--from-file=/path/to/file
# <type>: docker-registry, generic, tls

kubectl get secret <secret> -o yaml

# Taint
kubectl taint nodes <node> <key>=<val>:<taint-effect>
# <taint-effect>: NoSchedule, PreferNoSchedule, NoExecute (Existing pods will be evicted if intolerable to the taint)

# Kubeconfig
kubectl config view
kubectl config --kubeconfig=/path/to/kubeconfig use-context <user>@<cluster>
# Change ns to default
kubectl config set-context --current -n default

# Networking
kubectl get po -o wide # pod IP adr
kubectl get endpointslice <service-name> # service endpoint, from service metadata.name
kubectl port-forward <kind>/<name> 8080:80


kubectl exec -it <pod-name> -c <container-name> -- <CMD> # e.g. CMD: /bin/sh 
# left of --: args for kubectl
# right of --: cmd for container

exit # exit pod/container

# StatefulState
kubectl delete -f statefulset.yaml
kubectl delete pvc www-nginx-sts-0
kubectl delete pvc www-nginx-sts-1
kubectl delete pvc www-nginx-sts-2

# Rollback deployment to prev ver
kubectl rollout undo deploy <deplo-name> --to-revision=<revisionNumber>
