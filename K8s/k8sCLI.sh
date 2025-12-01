kubectl create -f ./k8s.yml
kubectl get rc # check replication controller status
ibid. rs # replica set status
kubectl describe
kubectl delete pod <podName> # delete a pod 
kubectl scale --replicas=4 -f ./k8s.yml # scale #pods

kubectl delete rc <replication-controllerName> --cascade=false
# pods will still work after delete controller
# Most use replicaSet/Deployment insted of replication-controller

kubectl set image deploy/<deployName> \
<podName>:<img-path>:<version> # e.g. <img-path>: dockerUsr/repos
# update image of a pod in a deployment

kubectl expose deploy <deployName> --type=NodePort --name=<serviceName>
# make a name for serviceName
minikube service <serviceName> --url # get service url


# Deployment
kubectl scale deploymenmt --replicas=1 <container> <container>...
# Scale down
--replicas=0
# Each container as a service
# my-deploymenmt is optional


# apply config (declarative)
kubectl apply -f <filepath> # pod/service/deployment/ingress etc. .yml
# delete config
kubectl delete -f <filepath>





# Context: a group of acc param to a k8s cluster
# Incl.: cluster, usr, namespace

kubectx <contextName> # kubectl config use-context

# get namespace
kubectl get ns

# get pods from default ns
kubectl get pods --namespace=kube-system

# change to default ns
kubectl config set-context --current --namespace=default


:'
Master node: aka control plane, do not run containers in the master
incl. kube-controller-manager
      cloud-controller-manager
      kube-scheduler: watch new pods which not yet assigned to a node
      select a node to run on

      etcd: store cluster state 
      kube-apiserver interact w/ etcd (datastore)

Worker node
incl. kubelet: run containers on the node
      kube-proxy: manage net rules on nodes
      container runtime
'

:'
Init container
app has depend. on A, but not to tie A w/ infra code
init a pod and remove init container before app container run 
'

kubectl get po -o wide # pod IP adr
kubectl get ep <serviceName> # service endpoint, from service metadata.name
kubectl port-forward <kind>/<name> 8080:80


kubectl exec -it <podName> -c <containerName> -- <CMD> # e.g. CMD: /bin/sh 
# left of --: args for kubectl
# right of --: cmd for container

exit 
# exit prog

# StatefulState
kubectl delete -f statefulset.yaml
kubectl delete pvc www-nginx-sts-0
kubectl delete pvc www-nginx-sts-1
kubectl delete pvc www-nginx-sts-2

# Rollback to prev ver of deployment
kubectl rollout undo deployment <deploymentName> --to-revision=<revisionNumber>

