# CKA

## Cheat sheet

```sh
# Gen template yaml
k run test-pod --image=busybox -n <ns> --dry-run=client -o yaml > pod.yml

k create deploy <deployment-name> \
  --image=nginx \
  --replicas=3 \
  --dry-run=client -o yaml > deployment.yml

# kubectl expose: Expose a resource as a new k8s service.
k expose deploy <deployment-name> \
  --name=<service-name> \
  --port=80 \
  --target-port=8080 \
  --type=NodePort \
  --dry-run=client -o yaml > service.yml

# Get Pods by labels
kubectl get pod -l lbl1=val1

# Get #resources
k get all --no-headers | wc -l

crictl ps # list static pods 
crictl logs <container>

# etcd
etcdctl endpoint status \
  --endpoints=https://<etcd_server>:2379 \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt 

# Env var
export ETCDCTL_ENDPOINTS=https://<etcd_server>:2379
export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt
export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key
export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt

# ---

# Doc & Ref
kubectl api-resources
kubectl explain <kind> --recursive # Align w/ yaml fields

# Taint
kubectl taint no <node> <key>=<val>:NoSchedule

# App Lifecycle Mgmt
kubectl rollout [ status | histroy | undo ] deploy <deployment>

kubectl auth can-i get svc --as system:serviceaccount:<ns>:<sa>
```

Resource Ref by name: `<name>.<ns>.<resource-kind>.<domain>`, e.g. `db-service.dev.svc.cluster.local`

Pod FQDN:

- `1-2-3-4.<ns>.pod.cluster.local`
- `<pod-ip>.<service-name>.<ns>.svc.cluster.local`

CNI:
***Install location:*** `/opt/cni/bin`
***Choose plugin:*** `/etc/cni/net.d`, by file lexicographical order

## Architecture



### Control Plane: Master nodes

- `kube-apiserver`: frontend, all comm. go thru the API server.
- `etcd`: kv store for cluster data. 
- `kube-scheduler`: assign pod to node. 
- `kube-controller-manager`: run controller proc to maintain *desired state*.

All components -> kube-apiserver -> kubelet
Component configs @`<master_node>:/etc/kubernetes/manifests`

### Data Plane: Worker nodes

- `kubelet`: agent on each node, mng pods & containers, comm. w/ control plane API server
- `kube-proxy`: proxy on each node, maintain rules to allow comm. to pods
- container runtime: software that runs containers (containerd, CRI-O), kubelet comm. w/ it via CRI.



## Docker vs. ContainerD

Container Runtime Interface (CRI): follow OCI standards, incl. image spec & runtime spec.

`nerdctl`: CLI for containerD, alt of `docker`.
`crictl`: CLI for all CRI compatible runtimes.

```sh
crictl ps # list static pods 
crictl logs <container>
```



## etcd

- Store: Nodes, Pods, Configs, Secrets, Accounts, Roles, Bindings, etc. in K8s.
- `kubectl get` retrieves from etcd
- etcd qua pod `etcd-<master_node>` in ns `kube-system`
- Store as directory structure: `/registry/[ Pods | ReplicaSets | Deployments | Roles | Secrets ]`

```sh
kubectl exec etcd-k8s-master -n kube-system -- etcdctl get / --prefix --keys-only

etcdctl [ get | put | del | txn | snapshot save ]
# txn: transaction
etcdctl endpoint status
etcdctl put k1 v1

etcdctl get / --prefix --keys-only \
  --endpoints=https://<etcd_server>:2379 \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt 

# Env var
export ETCDCTL_ENDPOINTS=https://<etcd_server>:2379
export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt
export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key
export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt
```



### HA

Multi Master nodes setup: `/etc/kubernetes/manifests/etcd.yaml`

```yml
spec:
  containers:
  - command:
    - etcd
    - --initial-cluster=<master-node-0>=https://${MASTER0_IP}:2380,<master-node-1>=https://${MASTER1_IP}:2380 \
    ...
```

```
ExecStart=/usr/local/bin/etcd \
  --initial-cluster <master-node-0>=https://${MASTER0_IP}:2380,<master-node-1>=https://${MASTER1_IP}:2380 \
  ...
```



## Kube-API

kubectl comm. w/ kube-api

Config file:

- Kubeadm: `/etc/kubernetes/manifests/kube-apiserver.yaml`  
- Scratch: `/etc/systemd/system/kube-apiserver.service`

Service CIDR: `--service-cluster-ip-range`

Change Service CIDR: update `kube-apiserver.yaml`, `kube-controller-manager.yaml`, apply new `ServiceCIDR` manifest, delete old `ServiceCIDR`.

## Controller-Manager (kube-controller-manager)

Monitoring the cluster

Pod CIDR: `--cluster-cidr`
Service CIDR: `--service-cluster-ip-range`

## Scheduler

Assign pod to node, Pod then created by `kubelet` on Worker

## Kubelet

Service rules to FW traffic
Manual setup kubelet on Workers
`ExecStart=/usr/bin/kubelet`

## Kube Proxy

`kube-proxy` qua `DaemonSet` on each node

## Pod

K8s scale by pod

Multi-container pod

- Main app container
- Sidecar container: logging, e.g. Thanos binded to Prometheus

```yml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
    description: "apiVersion, kind, metadata: dict, spec are required fields"
spec: 
  containers: # list 
  - name: nginx
    image: nginx
  - name: busybox
    image: busybox
```

**CANNOT edit existing Pod spec except:**

- `spec.containers[*].image`
- `spec.initContainers[*].image`
- `spec.activeDeadlineSeconds`
- `spec.tolerations`

If necessary, 

```sh
k get pod <pod> -o yaml > pod.yml
vi pod.yml # make changes
k delete pod <pod>
k apply -f pod.yml

# Alt
k edit <resource-kind> <resource-name>
k replace --force -f /tmp/def.yml
```

```sh
# List all images running in a cluster
k get pods -A -o custom-columns='DATA:.spec.containers[*].image'

# List all images running, group by Pod
k get pods -A -o custom-columns='NAME:.metadata.name,IMAGE:.spec.containers[*].image'
```



## Replica Set

```yml
apiVersion: apps/v1 # ReplicaSet must use apps/v1
kind: ReplicaSet
metadata:
  name: app-rs
  labels:
    app: myapp
    type: frontend
spec:
  template:
    metadata: ...
    spec: ...
  replicas: 3
  selector: 
    matchLabels:
      type: frontend
```

`kubectl scale --replicas=6 -f rs.yml`

cf. Label, Annotation, Selector
Delete old pods if using new Image: `kubectl delete pods -l lbl=val`

## Deployment

Deployment > RS > Pod Rolling update, rollback

```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  strategy:
    type: RollingUpdate
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```



### Pod Disruption Budget (PDB)

Limit #concurrent disruptions the app experience
`kubectl get pdb`

## Service

Headless service:

- `.spec.clusterIP: None`, required by STS.
- STS manifest: `.spec.serviceName: "service-name"`



### NodePort: Listen to node port and FW request to a spec. pod port

- Node Port: port on the Node, range 30000-32767
- Port: port on the Service
- Target Port: pod port 
External IP `curl http://<node-ip>:<node-port>` -> Node Port -> Port -> Target Port
Doesn't matter if there are multi pods across multi Nodes, use any Node IP, even no pod for a spec. service is on it.



### ClusterIP: virtual IP inside cluster, handle internal service comm.

- Scenario: micro-service for front-end <-> back-end <-> DB



### LB: only support cloud platform, ~ Node Port

```yml
apiVersion: v1
kind: Service
metadata:
  name: my-svc
spec: 
  type: NodePort
  ports: 
  - targetPort: 80
    port: 80
    nodePort: 30008
  selector:
    lbl1: val1
    lbl2: val2
```



## Namespace

```sh
k get <resource-kind> -n <ns>
k get <resource-kind> -A
```



### Ref to resource @ other ns: `<name>.<ns>.<resource-kind>.<domain>`

e.g. `db-service.dev.svc.cluster.local`

### Resource Quota

- Set per ns 
- cf. Limit Range

```yml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: dev
spec:
  hard:
    pods: "10"
    requests.cpu: "4"
    requests.memory: 5Gi
    limits.cpu: "10"
    limits.memory: 10Gi
```



## Explain

Reference
`kubectl api-resources`: list resource kinds
`kubectl explain <kind> --recursive`: align w/ yaml fields
`kubectl explain pod.spec.containers`: check spec. config option

# Scheduling



## Manual Scheduling

Pod-Node mapping @ `pod.spec.nodeName`

For existing Pod, if desired to schedule to another node, 

- Binding, then send POST request w/ JSON format.

```yml
apiVersion: v1
kind: Binding 
metadata: 
  name: nginx
target:
  apiVersion: v1
  kind: Node
  name: <node-name>
```

- Delete existing pod, then `kubectl apply` again.



## Label, Annotation, Selector



### Label

`kubectl get <resource-kind> <resource-name> --show-labels`

```yml
metadata:
  labels:
    key1: val1
    key2: val2
```



### Selector

`kubectl get pod -l lbl1=val1,lbl2=val2` 
`-l --selector`

```yml
selector:
  matchLabels:
    k: v
```

namespaceSelector: namespace has a label: `kubernetes.io/metadata.name` identical to its name.

```yml
namespaceSelector:
  matchLabels:
    kubernetes.io/metadata.name: prod
```



### Annotation:

Non-identifying metadata qui 3e-party tools / clients can retrieve

```yml
metadata:
  annotations:
    myapp.config/postgres-host: postgres-postgresql.postgres.svc.cluster.local:5432
    argocd.argoproj.io/sync-wave: "20"
```



## Taint & Toleration

Set restrictions on what pods can be scheduled on a node

### Taint

Set on Node
`kubectl taint no <node> <key>=<val>:<taint-effect>`

Taint effect: 

- NoSchedule
- PreferNoSchedule: Try not to schedule, but not guaranteed.
- NoExecute: Existing pods will be evicted if intolerable to the taint.



### Toleration

```yml
kind: Pod
...
spec:
  tolerations:
  - key: "k1"
    operator: "Equal"
    value: "v1" 
    effect: "NoSchedule"
```



## Node Affinity

```yml
kind: Pod
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution: # required: MUST
        nodeSelectorTerms:
        - matchExpressions:
          - key: size
            operator: In
            values:
            - Large
            - Medium
      preferredDuringSchedulingIgnoredDuringExecution: 
      # preferred: ideally schedule in nodes qui satisfy requirements, if not, still schedule

      # IgnoredDuringExecution: will not reschedule pods even env changed, e.g. Node label change.
```



## Resource Limits

`requests` <= resource allocation <= `limits`
Request qua floor, Limit qua ceiling

```yml
kind: Pod
spec: 
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: 2
        memory: 1Gi
      limits: 
        cpu: 4
        memory: 4Gi
```



## Limit Range

Constraint *per pod/container/PVC* in a ns.

```yml
kind: LimitRange
spec: 
  limits: 
  - default:
      cpu: 0.5
    defaultRequest:
      cpu: 0.5
    max: 
      cpu: 1
    min: 
      cpu: 0.1
    type: Container 
```



## Static Pods

- Created by `kubelet`
- Deploy Control Plane components qua static Pods
- Cannot mod / del thru `kube-api`
- Dir: `/etc/kubernetes/manifests`
- Config `staticPodPath` @`/var/lib/kubelet/config.yaml`



## Priority Class

Range: [-2147483648, 1000000000], Bigger -> higher

```yml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
globalDefault: false

---

kind: Pod
spec:
  priorityClassName: high-priority
```



## [Multi Schedulers](https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/)

Det Scheduler for a Pod @ Pod def: `spec.schedulerName`

### Scheduler Profiles

- Config diff. stages of scheduling. 
- Each stage qua extension point
- Plugins provide scheduling behaviours by implm 1+ extension points.



#### Extension Points

- `queueSort`: sort pending Pods in scheduling queue.
- `filter`: filter out nodes unable to run the Pod.
- `score`: provide a score to each node that has passed `filter` phase. The scheduler will then select the node w/  highest weighted scores sum.



#### Plugins

- `ImageLocality`: Favors nodes w/ imgs required by Pod. Extension points: score.
- `TaintToleration`: Extension points: filter, preScore, score.
- `NodeName`: Checks if a Pod spec node name matches the current node. Extension points: filter.
- `NodePorts`: Checks if a node has free ports for the requested Pod ports. Extension points: preFilter, filter.
- `NodeAffinity`: Implements node selectors and node affinity. Extension points: filter, score.

```yml
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
profiles:
  - schedulerName: default-scheduler
  - schedulerName: no-scoring-scheduler
    plugins:
      preScore:
        disabled:
        - name: '*'
      score:
        disabled:
        - name: '*'
```



## Admission Controller

kubelet -> Authn -> Authz (Basic perms: CRUD, list) -> Admission Controller (Adv perms) -> Create resource

- Block root user exec, latest, public img
`/etc/kubernetes/manifests/kube-apiserver.yaml`

```yml
kind: Pod
metadata:
  name: kube-apiserver
  namespace: kube-system
spec: 
  containers:
  - command:
  - kube-apiserver
  ...
  - --enable-admission-plugins=NodeRestriction, ...
  - --disable-admission-plugins=DefaultStorageClass, ...
```

List enabled Admission Controllers: `kubectl exec -n kube-system <kube-apiserver> -- kube-apiserver -h | grep enable-admission-plugins`

- Behaviour order: Mutating -> Validating

Admission plugins can be developed as extensions and run as webhooks config at runtime. 
Webhook response: 

- `uid`: `request.uid`
- `allowed`: bool

```yml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
webhooks:
- name: my-webhook.example.com
  clientConfig:
    caBundle: <CA_BUNDLE>
    service:
      namespace: my-service-namespace
      name: my-service-name
      path: /mutate
      port: 1234
  rules:
  - operations: ["CREATE","UPDATE","DELETE","CONNECT"]
    apiGroups: ["*"]
    apiVersions: ["v1"]
    resources: ["pods"]
```



# Logging & Monitoring

`kubectl logs -f <pod> [container]`
`-f`: log streaming
`<container>`: if a pod has multi container, requires to spec container name

# App Lifecycle Mgmt

`kubectl rollout [ status | histroy | undo ] deploy <deployment>`

Strategy

- Rolling Update: default, take down and create new, one by one.
- Recreate: destroy all and create new



## Commands & Args, Env var

```yml
kind: Pod
spec: 
  containers:
  - name: busybox
    image: busybox
    command: ["sh", "-c", "sleep 3600"]
    env:
    - name: ENV_VAR
      value: "1234"
    - name: NODE
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
```

cf. Config Map, Secret

K8s - Dockerfile mapping

- `command` - `ENTRYPOINT`
- `args` - `CMD`



## Config Map

`kubectl create cm foo --from-file=app.properties`
`--from-file`: key: filename, value: content
`--from-env-file`: creates separate keys

```yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_COLOR: blue

---

# Injection to Pod
kind: Pod
spec:
  containers:
  - name: nginx
    image: nginx
    envFrom:
    - configMapRef:
        name: app-config
        key: APP_COLOR # If only 1 env var desired
```



## Secret

```sh
k create secret <type>

k create secret generic <secret> \
  --from-literal=<k>=<v> \
  --from-file=/path/to/file
```

`<type>`: `generic`, `tls`, `docker-registry`

Read: `kubectl get secret <secret> -o yaml`

```yml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
data:
  username: base64-encoded-plaintext # echo -n password | base64
  password: cGFzc3dvcmQ=

---
# Injection to Pod

kind: Pod
spec:
  containers:
  - name: nginx
    image: nginx
    envFrom:
    - secretRef:
        name: app-secret
        key: password # If only 1 env var desired
    env:
    - name: DB_PASSWORD # custom env var name 
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: password
```

Secrets in Pod qua Volume

```yml
volumes:
- name: app-secret-vol
  secret:
    secretName: app-secret
```

```sh
ls /opt/app-secret-vol
# Each secret key qua file
cat /opt/app-secret-vol/password
```



## Multi-Container Pod Design Pattern

- Co-located: containers dep on each other
- Init container: `spec.initContainers`
- Sidecar: sidecar init first, but still continues.
`spec.initContainers.restartPolicy: Always`



## HPA

`kubectl autoscale deploy <deployment> --min=2 --max=10`

```yml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50 
  - type: Pods
    pods:
      metric:
        name: requests-per-second
      target:
        type: AverageValue
        averageValue: 1k
```



# Maintenance



## Versioning: x.y.z

e.g. 1.35.5
y: minor version
`kubectl get no`: show kubelet ver

## Constraints

- `kube-apiserver`: y
- `controller-manager`: y-1
- `kube-scheduler`: y-1
- `kubelet`: y-2
- `kube-proxy`: y-2
- `kubectl`: [y-1, y+1]



# Security



## Cert

[Issue cert for a K8s API client using a CSR](https://kubernetes.io/docs/tasks/tls/certificate-issue-client-csr/)

1. PKI prep

```sh
# Gen private key
openssl genrsa -out <user>.key 3072
# Gen CSR
openssl req -new -key <user>.key -out <user>.csr -subj "/CN=<user>"
# Encode as Base64
cat <user>.csr | base64 | tr -d "\n"
```

1. Create a CertificateSigningRequest resource

```yml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: <user>
spec:
  request: # Base64 encoded contents of user.csr
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # 1D
  usages:
  - client auth
# kubectl apply -f <csr>.yml
```

1. Approve CSR, get cert

```sh
k get csr
k certificate approve <user>
k get csr <user> -o yaml
# Export cert
k get csr <user> -o jsonpath='{.status.certificate}'| base64 -d > <user>.crt
ls # <user>.key, <user>.csr, <csr>.yml, <user>.crt
```

1. Config cert into kubeconfig

```sh
# Add cred (user)
k config set-credentials <user> --client-key=<user>.key --client-certificate=<user>.crt --embed-certs=true
k config set-context <user> --cluster=kubernetes --user=<user>
k --context <user> auth whoami
```

1. Create RBAC: Role & RoleBinding

```sh
k create role <role> --verb=create,get,list --resource=pods,svc
k create rolebinding <role-binding> --role=<role> --user=<user>
```



## KubeConfig

Default:`~/.kube/config`

Temp kubeconfig

```sh
export KUBECONFIG=/path/to/kubeconfig
unset KUBECONFIG
```

```sh
k config set-context --current -n <ns>
k config view
k config --kubeconfig=/path/to/kubeconfig use-context developer@development

k config get-contexts --kubeconfig=/path/to/kubeconfig -o name 

k config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' \
  --kubeconfig=/path/to/kubeconfig \
  | base64 -d
k config view --raw --kubeconfig=/path/to/kubeconfig -o json | \
  jq -r '.users[] | select(.name == "account-0027") | .user."client-certificate-data"' | base64 -d 
```

```yml
apiVersion: v1
kind: Config
current-context: developer@dev
clusters:
- name: dev
  cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt
    server: https://k8s.example.org/k8s/clusters/c-xxyyzz
  
users:
- name: developer
  client-certificate: /etc/kubernetes/pki/users/developer.crt
  client-key: /etc/kubernetes/pki/users/developer.key

contexts:
- name: developer@dev
  context:
    cluster: dev
    user: developer
    namespace: finance
```



### Kubectx

```sh
kubectx <ctx> # (<user>@<cluster>)
kubectx -     # prev context
kubectx -c    # current context
```



## API Groups

1. Core group (`/v1`): ns, pod, node, PV, PVC, secret, svc, cm
2. Named group (`/apis`):

- `/apps`: deploy, replicaset, statefulset
- `/networking.k8s.io`
- `/certificates.k8s.io`: Certificate Signing Request



## Authz



### RBAC

- **Role**: rules for a set of perms. set perm w/in a parti ns. ***positive***, i.e. no deny rules.
- **ClusterRole**: non-ns resource
- **RoleBinding**: grants perm to users, spec ns. But when ref. to a ClusterRole, the *subject* only has acc to the parti ns.
- **ClusterRoleBinding**: grant perm to whole cluster

```yml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: <ns>
rules:
- apiGroups: [""] # core group
  resources: ["pods"]
  verbs: ["list", "get", "create"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: <ns>
subjects:
- kind: User
  name: dev-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```

Check acc.

```sh
k get roles
k get rolebindings
k auth can-i <verbs> <resource-kinds> --as <username>
# e.g.
k auth can-i list deployments
k auth can-i get svc --as system:serviceaccount:<ns>:<sa>

```



## Service Account

Service Account: ID
Token: barcode on ID

```sh
TK=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl -k https://kubernetes.default/api/v1/secrets -H "Authorization: Bearer ${TK}"
```



### Internal Service

- Each NS has a default SA
- default SA auto attached to pod on creation
K8s does the following automatically:
- create tk and mount as projected volume
- rotate tk
- expire tk on pod deletion



### External Service

`kubectl create token <tk-name> --duration <duration>`

## Pull Image from Private Registry

```sh
kubectl create secret docker-registry <regcred> \
  --docker-server <Docker-private-registry-FQDN> \
  --docker-username <username> \
  --docker-password <password> \
  --docker-email <email>

kubectl get secret <regcred> -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d
```

```yml
spec:
  containers:
  ...
  imagePullSecrets:
  - name: <regcred>
```



## Security Context

- At Pod or Container lvl
- Config @ Container lvl will override Pod lvl

```yml
spec:
  securityContext: # Pod lvl
    runAsUser: 1000
  containers:
  - name: nginx
    ...
    securityContext: # Container lvl
      runAsUser: 1000
      capabilities: # Capabilities only @ Container lvl
        add: ["MAC_ADMIN"]
```



## Network Policy

- Pods can comm. w/ each other by default
- Network Policy assigned to a Pod will override the setting
- Only concern requests, resp will send back automatically.

```yml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
spec:
  podSelector: # Impose policy on Pods
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  - Egress
  ingress: # 1 item as 1 rule: Rule 1: - from: {} ports: {}, Rule 2: - from: {} ports: {},...
  - from: 
    # with `-` qua item: OR logic, satisfy 1 of the sources
    # w/o `-`: AND logic, podSelector & namespaceSelector
    - ipBlock:
        cidr: 172.17.0.0/16
    - podSelector:
        matchLabels:
          role: frontend
      namespaceSelector: 
        matchLabels:
          kubernetes.io/metadata.name: prod # label value: name of ns.      
    ports:
    - protocol: TCP
      port: 6379
  egress:
  - ports: 
    - protocol: TCP
      port: 5978
```



## CRD

```yml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: shirts.stable.example.com # <plural>.<group>
spec:
  group: stable.example.com # group: 
  scope: Namespaced
  names:
    plural: shirts
    singular: shirt
    kind: Shirt
    shortNames:
    - sh
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              color:
                type: string
              size:
                type: string

---
# CR def
apiVersion: stable.example.com/v1 # <group>/<version>
kind: Shirt
metadata:
  name: my-shirt
spec: 
  color: red
  size: large
```

Apply wrong CRD & CR defs rollback

```sh
rm -rf ~/.kube/cache
kubectl apply -f crd.yml
kubectl apply -f cr.yml
```



## Operator Framework

Def. CRD & Custom Controller as one

Custom Controller

- Monitor etcd
- Change state via API
- Written in Golang



# Storage



## Storage in Docker

Copy-on-Write

- Container layer: RW, copy from image layer to write
- Volume/Bind: mid-layer, Bind is a dir on anywhere, Container layer write is stored here
- Image layer: read-only, base layer

Storage driver: mng storage on img & container, e.g. aufs, zfs
Volume driver: create volume on docker host, e.g. local, Azure File Storage, NetApp, Portworx, vSphere Storage
`docker run -it --name mysql --volume-driver <vol-driver> --mount src=vol,target=/var/lib/mysql mysql`

## Persistent Volume (PV)

```yml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: block-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  volumeMode: Block
    # Block: volume not be formatted w/ a FS and remain a raw block device.
    # Filesystem: volume formatted w/ a FS.
```



## Persistent Volume Claim (PVC)

```yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: claim-1
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  volumeName: block-pv # If ref to PV over Storage Class
  volumeMode: Block
  resources:
    requests:
      storage: 8Gi
  selector:
    matchLabels:
      release: "stable"

---

kind: Pod
spec: 
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - mountPath: var/www/html
      name: pod-nginx
  volumes:
  - name: pod-nginx
    persistentVolumeClaim:
      claimName: claim-1
```



## Storage Class

- Dynamic PV provisioning
- No need for PV def

```yml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: sc-1
provisioner: kubernetes.io/no-provisioner # Local 
  # Alt: rancher.io/local-path
  # provisioner opt: EBS, Portworx, Ceph, NFS, vSphere, Azure Disk
reclaimPolicy: Retain # default: Delete
volumeBindingMode: WaitForFirstConsumer
```

Some `mountOptions` config

```yml
mountOptions:
  - dir_mode=0777
  - file_mode=0777
  - uid=100
  - gid=1000
  - noperm
```



# Networking

Network Namespace: virtual interface w/in a host
Bridge: virtual switch w/in a host, in order to connect network ns'es

## CNI plugins

***Install location:*** `/opt/cni/bin`

***Choose plugin:*** `/etc/cni/net.d`, by file lexicographical order

## CoreDNS

- CoreDNS server: `Pod` (ReplicaSet)
- CoreDNS: `ConfigMap` or Corefile: `kubectl describe cm -n kube-system coredns` 
- CoreDNS service: `kube-dns` exposes CoreDNS pods. CoreDNS recv requests from pods, check if it's w/in cluster service. If not, i.e. external, it forwards the query to the upstream DNS servers.



### Query proc

1. Check most spec zone for the query (longest suffix match), e.g. 2 servers: `example.com`, `a.example.com`, query: [www.a.example.com](http://www.a.example.com), will match `a.example.com`.
2. Server found → route to Plugin Chain, in the same order.
3. Each plugin inspect & det the query
  a. Processed
  b. Not processed: if last plugin → return SERVFAIL
  c. Fallthrough: query is proc by the plugin, but half way thru it decides it still wants to call the next plugin in the chain.
  d. Hint: added by the cur. plugin for the next plugin, it provides a way to see the resp and act.

`.:53`: responsible for all zones, default DNS port 53.
Spec plugins in the Server Block.

```
.:53 {
    errors
    health {
       lameduck 5s
    }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       fallthrough in-addr.arpa ip6.arpa
       ttl 30
    }
    prometheus :9153
    # FW alt: 8.8.8.8
    forward . /etc/resolv.conf { # file @ node
       max_concurrent 1000
    }
    cache 30 {
       disable success cluster.local
       disable denial cluster.local
    }
    loop
    reload
    loadbalance
}
```



## Ingress

Route traffic per

- Path (/subpath)
- Hostname (app1.example.com)

```yml
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: / # All sub-paths will lead to root(/)
spec:
  ingressClassName: nginx # if using NGINX
  rules: 
  - host: example.com
    http:
      paths:
      - path: /
```

Create

- Ingress Controller (Deployment)
- Ingress Resource (Ingress)



## Gateway API

Layer 4-7 routing

- `GatewayClass`: infra provider, e.g. Envoy, Istio
- `Gateway`: cluster operator. A network endpoint to proc. traffic
- `HTTPRoute`, `GRPCRoute`, `TCPRoute`: app developer

Gateway HTTPS conf

```yml
kind: Gateway
spec:
  gatewayClassName: nginx
  listeners:
  - name: https
    protocol: HTTPS
    port: 443
    hostname: example.com
    tls:
      certificateRefs:
      - name: example-com-tls # Secret in K8s 
```

HTTPRoute auto FW by User-Agent

```yml
kind: HTTPRoute
spec:
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /auto
      headers:
      - type: Exact # header value = spec. value
        name: user-agent
        value: mobile
    backendRefs:
    - name: web-mobile
      port: 80
```

```sh
curl example.com:30080/auto -H "User-Agent: mobile" 

# Test Ingress / GW
ING=$(k get ingress main-ing -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -vk --resolve example.com:443:${ING} https://example.com

GW=$(k get gtw main-gw -o jsonpath='{.status.addresses[0].value}')
curl -vk --resolve example.com:443:${GW} https://example.com
```



# Design Cluster



## Storage

- Hi Performance: SSD
- Multi concurrent conn: net-based storage
- Multi Pods acc.: shared PV
- Label nodes w/ disk types
- Node selector to assign apps to nodes w/ spec. disk types



## Infra Selection

- Turnkey: self-provision, config, maintain VMs, e.g. OpenShift, Cloud Foundry Container Runtime.
- Hosted: Provider mng K8s, e.g. EKS, AKS, GKE, OpenShift Online.



## Quorum: N/2 + 1, #nodes: odd



# Helm

```sh
helm search [hub, repo] <chart>
helm repo add <repo> <url>
# <release>: custom name
helm [install, upgrade] <release> <repo>/<chart> --values values.yaml

helm list # list releases deployed
helm history <release>
helm rollback <release> [revision]
helm uninstall <release>
```



# Kustomize

- DRY configs in diff. stages, e.g. dev, stage, prod



### Project Structure

.
├── base
│   ├── deploy.yml
│   ├── gw.yml
│   └── service.yml
├── components
│   └── db
│       ├── deployment-patch.yaml
│       ├── kustomization.yaml
│       └── postgres-depl.yaml
├── kustomization.yaml
└── overlays
    ├── dev
    │   ├── kustomization.yaml
    │   └── replicas.yml
    ├── prod
    │   ├── kustomization.yaml
    │   └── replicas.yml
    └── stage
        ├── kustomization.yaml
        └── svc-nodeport.yml

```sh
kubectl [apply, delete] -k ./
kubectl kustomize ./
```

Kustomize looks at `kustomization.yaml`

- @ root: `resources` field: list all sub-dir.
- @ sub-dir: `resources` field: all manifests w/in.
- `overlays/[dev,test,prod]/`: `resources` field: `../../base`, all manifests w/in.

`kustomization.yaml`

```yaml
# apiVersion & kind not required, but still recom to specify
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Base K8s manifests
resources:
  - ../../base
  - namespace.yaml

# Transformers: add names & lbls on k8s manifest metadata
namePrefix: dev-
nameSuffix: -team-backend
labels:
- pairs:
    lbl1: val1
  includeSelectors: true

# Image Transformers: mod Img to deploy and Tag (ver)
images: 
  # name & newName are irrelevant to containers.name in k8s manifest, but containers.image
  - name: <image (nginx)>
    newName: <image>
    newTag: 2.4

patches:
  - path: deployment-patch.yaml # Separate file 
  - patch: |- # Strategic merge patch
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: api-deployment
      spec: 
        replicas: 5 ### Replace
        template:
          metadata:
            labels:
             org: null ### Delete dict item
        containers:
          - $patch: delete ### Delete list item
            name: nginx
  - target: # JSON 6902 patch
      kind: Deployment
      name: api-deployment
    patch: |-
      - op: [add, remove, replace]
        # Replace list item w/ index#: /path/to/list/0
        # Append list item: /path/to/list/-
        path: /spec/template/spec/containers/0/image
        value: busybox

components: # Configs used by multi overlays
  - ../../components/db

# Gen dynamic config from literal values or files
configMapGenerator:
  - name: app-config
    literals:
      - LOG_LEVEL=debug
    files:
      - settings.yaml
    env:
      - .env
```



# Troubleshooting



## Pending Pods

Check Event section for FailedScheduling: `kubectl describe po <pod>`

## Application Failure

Check

1. Web Service
2. Web Pod `kubectl logs -f <pod> -p`

`-p`, `--previous`: previous instance of a container / pod
3. DB Service 
4. DB Pod

## Control Plane Failure

Control plane component qua

- pod: `kubectl logs -n kube-system kube-apiserver`
- systemd service: `journalctl -u kube-apiserver | tail -n 50`



## `NotReady` Node

- `kubelet` on worker node is not running
- Network partition preventing comm. w/ API server

```sh
ssh <worker_node>
systemctl status kubelet
journalctl -f -u kubelet
```



## Networking

1. Check Pod
2. Check Pod direct connectivity
  ```sh
  k get po -o wide # get Pod IP

  k run busybox -it --rm --restart=Never --image=busybox sh
  wget -qO- <Pod_IP>:<port> # -O <file>: If - as file: stdout

  # Endpointslices: Pods selected by Service (by selectors)
  # EndpointSlice controller auto add label: `kubernetes.io/service-name` to link an EndpointSlice to its parent Service.
  k get endpointslices -l kubernetes.io/service-name=hostnames

  k get netpol # network policy
  ```
3. CoreDNS
  ```sh
  k get po -n kube-system -l k8s-app=kube-dns
  # k8s-app lbl: for Kubernetes system component
  k get endpointslice -n kube-system -l kubernetes.io/service-name=kube-dns


  k exec -it <problematic_pod> -- cat /etc/resolv.conf
    # kube-dns IP
    # search: shortname
    # ndots: 5

  k exec -it --rm busybox -- nslookup 192-168-16-25.default.pod.cluster.local # nslookup a pod 
  k exec -it --rm busybox -- nslookup kubernetes.default.svc.cluster.local
  k exec -it --rm busybox -- nslookup my-app-svc.default.svc.cluster.local
  ```
4. CNI

- check CNI DaemonSet pods
- check CNI pod logs

1. Kube-proxy
  ```sh
  k get po -n kube-system -l k8s-app=kube-proxy
  k logs -n kube-system <kube-proxy-pod> 
  k get cm -n kube-system kube-proxy -o yaml

  iptables-save | grep <service-name>
  iptables -t nat -L -n
  ```



## Events

```sh
kubectl get events -A --sort-by='.lastTimestamp' --field-selector type=Warning

# Events for a specific Pod
kubectl get events -n <ns> \
  --field-selector involvedObject.name=<pod>
```



# JSON Path

- `''` to include whole query 
- `{}` for each sub-query
- `{range .items[*]} {expr} {end}`: loop
- No need `.items[idx]` for `--sort-by` and `-o custom-columns`

```sh
k get no -o jsonpath='{range .items[*]} {.metadata.name} {"\t"} {.status.capacity.cpu} {"\n"} {end}'

k get no --sort-by=.spec.capacity.storage -o custom-columns=NODE:.metadata.name,CPU:.status.capacity.cpu

# Select: ?(@.field=="value")
-o jsonpath='{.contexts[?(@.context.user=="aws-user")].name}'
```

