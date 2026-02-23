# Argo CD
Decl. GitOps CD tools for K8s

## Core Concepts
- Application: group of K8s resources qua manifest / CRD.
- Sync status: check live state matches target state. 
- Sync: sync live state to target state.

## Helm qua Tool

### Values
```
argocd app set helm-guestbook --values <values.yml>

# Set params
argocd app set helm-guestbook -p service.type=LoadBalancer
# equiv
helm template . --set service.type=LoadBalancer
```

`helm-guestbook.yml`
```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd

spec:
  project: default 

  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: helm-guestbook

    helm:
      valueFiles:
      - values-production-2.yaml
      - values-production-1.yaml
      # If dup occur in 2 value files, latter will overwrite the former, in casu 1 over 2.

      parameters:
      - name: "service.type"
        value: LoadBalancer
      
      # Helm ver
      version: v3
  
      # passCredentials: default prevents sending repo creds to download charts from diff. domain than the repo. Set true if necessary.
      passCredentials: true 

  # Destination Cluster and Namespace
  destination:
    server: https://kubernetes.default.svc
    namespace: guestbook

  # Sync Policy (Automated syncing)
  syncPolicy:
    automated:
      prune: true      # Delete resource no longer in Git
      selfHeal: true   # Reset resource if someone manual mod 
    syncOptions:
      - CreateNamespace=true # Auto create 'guestbook' ns if missing
```

Sync Options config in Resource def., viz. pod, deployment, DaemonSet, service, PV, PVC, Secret, ConfigMap, etc.
```
metadata:
  annotations:
    argocd.argoproj.io/sync-options: Prune=false # never prune the resource.
    # Prune=confirm: manual confirm pre-prune.
```

#### Precedence (Hi->Lo)
General: params -> valuesObject -> values -> valueFiles

W/in each: last file/param listed has Hi precedence, e.g. `helm-guestbook.yml`: `values-production-1.yaml`

### Hooks
Argo CD does not know if it's first-time running `install` or `upgrade`, all treated as `sync`. viz. app w/ `pre-install` and `pre-upgrade` will have those hooks run at the same time.

- Make Hooks idempotent.
- Annotate `pre-install`, `post-install` w/ `hook-weight: "-1"`: Ensure it runs till success before upgrade hooks.
- Annotate `pre-upgrade`, `post-upgrade` w/ `hook-delete-policy: before-hook-creation`: Ensure it runs on every sync.

```
kind: Job
metadata:
  annotations:
    "helm.sh/hook": post-install # pre-install
    "helm.sh/hook-weight": "-1"
```

*cf. Sync Phases & Sync Waves*


[Argo CD Hooks](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/)

[Helm Hooks](https://helm.sh/docs/topics/charts_hooks/)

### Helm Plugins
Install custom plugins by ArgoCD container img / initContainer

[Code snippets for ArgoCD container img / initContainer](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/#helm-plugins)

## Directory qua Tool
Load `.yml`, `.yaml`, `.json`

```
spec:
  source:
    directory:
      # Recursive resource detection
      recurse: true
      exclude: '{config.json,env-usw2/*}' # exclude file: config.json & dir: env-usw2
      include: '*.yml'
```


`# +argocd:skip-file-rendering`: Add the line to Skip YAML files which are not manifests, e.g. `values.yaml`

## Tool Detection
Default: Directory

Implicit detect:
- Helm: `Chart.yaml`
- Kustomize: `kustomization.yaml`, `kustomization.yml`, `Kustomization`

## Project
Logical app grouping for teams.

`default` proj: all perms, can be mod, but not deleted

Control: 
Deployment
- What: Git repo.
- Where: dest. cluster/ns.
- Kind of obj: RBAC, CRD, DaemonSets, etc.
- Def proj roles for app RBAC.

```
# Create proj
argocd proj create proj-1 \
-d https://kubernetes.default.svc,<ns-1> \ -s https://github.com/argoproj/argocd-example-apps.git

# Assign app to proj
argocd app set guestbook-1 --project proj-1
```
### RBAC
Policy Syntax: `p, <role/user/group>, <resource>, <action>, <object>, <effect>`

Detailed Syntax: `p, proj:<proj-name>:<role-name>, <resource>, <action>, <object>, <effect>`

- `p`: p for policy
- `resource`: applications, applicationsets, clusters, projects, repositories, accountes, certificates, gpgkeys, logs, exec, extensions.
- `action`: get, create, update, delete, sync, action, override, invoke.
- `effect`: allow, deny

[RBAC](https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/#rbac-model-structure)

#### JWT Tk
Auth to a role.

Tk asso. to a role's policies, any change to the policies will take effect for the JWT tk.

Pass tk by `--auth-token` flag, or env var `ARGOCD_AUTH_TOKEN`

---

vide `proj-1.yml`

## Private Repo
HTTPS userpass cred. 

CLI:
```
argocd repo add https://github.com/argoproj/argocd-example-apps \
  --username <username> --password <password>

# TLS client cert for auth
argocd repo add https://repo.example.com/repo.git --tls-client-cert-path ~/cert.crt --tls-client-cert-key-path ~/cert.key

# SSH: git@ or ssh://
argocd repo add https://repo.example.com/repo.git --tls-client-cert-path ~/mycert.crt --tls-client-cert-key-path ~/mycert.key
```

UI:
Settings/Repositories -> Connect Repo using HTTPS

Alt: Access tk
([GitHub Access tk](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens))

TLS certs are config-ed per-server, not per-repo. If you connect multiple repos from the same server, you only have to config certs once for this server.


### Cert Mgmt
`--insecure-skip-server-verification`: flag to skip server verification, dangerous, only in non-prod.

`add-tls --from <cert_path>`: self-signed CA cert.
```
# List certs
argocd cert list --cert-type [https|ssh]

# Skip server verification: 
argocd repo add --insecure-skip-server-verification https://git.example.com/test-repo

# Self-signed CA cert
argocd cert add-tls git.example.com --from ~/CA_CERT.pem
argocd repo add https://git.example.com/test-repo
```

## Auto Sync Policy
- Auto sync only works if app is OutOfSync. Synced and error will not trigger.
- Rollback not allowed if auto sync enabled
```
spec:
  syncPolicy:
    automated: {}
```

- Auto Prune: delete resources no longer in Git for auto sync by default will NOT delete.
- Auto Self-heal: auto sync when live cluster state deviates from Git defined state.
- Auto Retry Refresh: Refresh on new revisions: `git commit`, `git push`, when the cur sync is retrying.

```
spec:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    retry:
      refresh: true
```

```
# Auto sync
argocd app set <app> --sync-policy automated

# Auto prune
argocd app set <app> --auto-prune

# Auto retry refresh
argocd app set <app> --sync-retry-refresh
```
## Diff Strategies
### Legacy
Default. Apply a 3-way diff based on live state, desired state and last-applied-configuration (annotation).

### Server-Side Diff
Server-Side Apply in dryrun mode for each resource of the app. 

Dryrun resp compared w/ live state, and provide diff results. 

Diff results cached, and new Server-Side Apply requests to Kube API are only triggered when:
- Refresh request
- New revision
- Argo CD app spec changed.
- Resouce ver. of resource per se in live state changed.

Enable lvl: Argo CD Controller (all apps), app

- Argo CD Controller (all apps) lvl:
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cmd-params-cm
data:
  controller.diff.server.side: "true"
```
*N.B.* restart `argocd-application-controller` after applying this configuration.

- App lvl:
```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  annotations:
    argocd.argoproj.io/compare-options: ServerSideDiff=true,IncludeMutationWebhook=true
```
`ServerSideDiff=false` disable spec. app if Controller lvl enabled.

`IncludeMutationWebhook=true` when:
- Service mesh sidecars, e.g. Istio, Linkerd, Consul
- Secret injectors: HashiCorp Vault
- Auto resource labelling.
- Safe to set it by default.

## Orphaned Resource Monitoring
Top-lvl namespaced resource, does not belong to any Argo CD app.
```
kind: AppProject
spec: 
  orphanedResources:
    warn: true
    ignore:
    - kind: ConfigMap
      name: cm-1
```
App target ns w/ orphan will get a warning.

Resources NOT considered orphans:
- Namespaced resources Denied in the proj. Usually mng by cluster admin.
- Name of `ServiceAccount`: `default`
- Name of `Service`: `kubernetes` in `defualt` ns. 
- Name of `ConfigMap`: `kube-root-ca.crt` in all ns

## Env var
`ARGOCD_SERVER=argocd.example.com`, no `https://` prefix.

`ARGOCD_AUTH_TOKEN=<access_tk>`

## Sync Phases & Sync Waves
Phases & Hooks def when resources are applied pre/post sync. 

### Hook Types (Phase)
- Hook qua Pod, Job, Argo Workflows.
- `argocd.argoproj.io/hook` annotation.

`PreSync`: prior to everything.

`Sync`: post-PreSync, during app apply.

`Skip`:	skip manifests.

`PostSync`:	post-Sync, all resources in Healthy state.

`SyncFail`: ex vi termini.

---

`PreDelete`: pre App resource deletion. Only runs on entire App deletion, not in normal sync (even w/ prune).

`PostDelete`: post resource deletion.

Sync:
PreSync -> Sync [Success, Fail]-> PostSync, SyncFail

Deletion:
`kubectl delete <application>`, `argocd app delete` trigger `PreDelete` & `PostDelete`.

### Sync Waves
- Sync order w/in each phase (PreSync, SyncFail...).
- `argocd.argoproj.io/sync-wave` annotation: Default: 0, asc order, negative allowed.
- `ARGOCD_SYNC_WAVE_DELAY`: env var, delay inter-sync wave, default: 2s, give time for controllers to react.

### Precedence: phase -> sync wave -> kind (ns -> k8s resources -> CRD) -> name

```
metadata:
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/sync-wave: "-20"
```

Examples: Slack notification post-sync, DB migration pre-sync. [Hooks, Sync Phases, Sync Waves](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/#examples)

#### Mapping to Helm Hooks
PreSync -> helm.sh/hook: [pre-install|pre-upgrade]

PostSync -> helm.sh/hook: [post-install|post-upgrade]

PreDelete -> helm.sh/hook: pre-delete

PostDelete -> helm.sh/hook: post-delete

sync-wave -> helm.sh/hook-weight

argocd.argoproj.io/hook-delete-policy -> helm.sh/hook-delete-policy

[Helm qua Tool](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/)

## Sync Windows
Time window
`allow` / `deny`: `deny` first.
`schedule`, `duration`, `applications`, `namespaces`, `clusters`

`timeZone`, `manualSync`

```
kind: AppProject
spec:
  syncWindows:
  - kind: allow
    schedule: '10 1 * * *'
    duration: 1h
    applications:
    - '*-prod'
  - kind: deny
    schedule: '0 22 * * *'
    timeZone: "Europe/Amsterdam"
    duration: 1h
    namespaces:
    - default
    manualSync: true
  - kind: allow
    schedule: '0 23 * * *'
    duration: 1h
    clusters:
    - in-cluster
    - cluster1

```

## Sync App w/ kubectl
`apply`: tell Argo CD to `kubectl apply`.

`hook`: submit any resource being ref in the operation.
```
kind: Application
operation:
  sync:
    prune: true # prune pre-apply, for idempotency
    syncStrategy:
      apply: {}
      hook: {}
```

## ApplicationSet
- Improve multi-cluster, cluster multi-tenant support.
- Allow developers w/o acc to Argo CD ns to create Apps w/o cluster admin.
- Idempotent

vide `ApplicationSet.yml`

## Best Practices
- App of Apps pattern: K8s manifests (Deployment, Service) as 1 repo, Argo CD CRD (Application, AppProject)as 1 repo. 
- HPA, VPA: remove `replicas`, `ignoreDifferences` in Argo CD.
```
spec:
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas
```
[Diffing Customization](https://argo-cd.readthedocs.io/en/stable/user-guide/diffing/)

- Manifest sync as Annotation.
```
kind: <k8s-kind>
metadata:
  name: my-service
  annotations:
    argocd.argoproj.io/sync-options: Prune=false
    argocd.argoproj.io/sync-wave: "5"
    argocd.argoproj.io/hook: PostSync
```

## References
[Argo CD Annotations & Labels](https://argo-cd.readthedocs.io/en/stable/user-guide/annotations-and-labels/)

[CLI](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd/)

[Application Config](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/)