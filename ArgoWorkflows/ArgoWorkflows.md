# Argo Workflows
- Orch parallel jobs on K8s
- Retry mechanism
- Large scale parallel pods & workflows mgmt
- ML, ETL, Batch/Data proc, CI/CD

```
ARGO_WORKFLOWS_VERSION="vX.Y.Z"
kubectl create namesapce argo
kubectl apply -n argo -f "https://github.com/argoproj/argo-workflows/releases/download/${ARGO_WORKFLOWS_VERSION}/quick-start-minimal.yaml"
```

## Analogy
- WorkflowTemplate: lib, class
- Template: func
- Step / Task: func call
- Artifact Repo: Disk, S3 bucket
- Inputs / Outputs: Arg / Return

## Submit
CLI
```
argo submit -n argo <workflow.yml>
argo list -n argo 
argo get -n argo @latest
```

UI: `kubectl -n argo port-forward service/argo-server 2746:2746`

`argo submit` w/ Workflow files, `kubectl apply` w/ all other files (WorkflowTemplate, CronWorkflow).

## Workflow
- Def. single instance of a Workflow
- Each step qua container
- `Workflow.spec`: `templates` list, `entrypoint`.

`workflow.yml`
```
kind: Workflow
spec:
  templates:
  - name: main
    steps:
    - - name: add
        template: call-template
        arguments: ...

  - name: call-template # func name
    templateRef:
      name: template-1
      template: template
```

```
argo submit <workflow.yml> # submit WF
argo list # list cur WF
argo delete <workflow-id>
```

### CronWorkflow
```
kind: CronWorkflow
metadata:
  name: test-cron-wf
spec:
  schedules:
    - "* * * * *"
  timezone: Europe/Amsterdam
  concurrencyPolicy: "Replace"
  startingDeadlineSeconds: 0
  workflowSpec:
    entrypoint: date
    templates:
    - name: date
      container: ...
```


## Template
Def works / tasks TB done, like functions

### 9 Kinds
1. `container`
2. `script`: `source` field to def a script in-place.
3. `resource`: op on cluster resource, get, create, apply, delete, replace, patch.
4. `suspend`: suspend execution, controlled by duration or manual resume. Resume from CLI: `argo resume`, API, UI.
5. `plugin`: ref exec plugin.
6. `containerSet`: spec multi containers w/in a pod.
7. `http`: exec HTTP requests.

#### Template Invocators: call other templates and provide exec control.
8. `steps`: list of lists structure, in order to run seq. Get rid of outer list `-` to run parallel.
    step1 -> step2a & step2b (parallel)
    ```
    - name: steps-tmpl
      steps:
      - - name: step1
          template: prepare-data
      - - name: step2a
          template: run-data-1e-half
        - name: step2b
          template: run-data-2e-half
    ```
9. `dag`: def tasks as graph of dependencies. 
    A -> B & C (parallel) -> D
    ```
    - name: diamond
      dag:
        tasks:
        - name: A
          template: echo
        - name: B
          dependencies: [A]
          template: echo
        - name: C
          dependencies: [A]
          template: echo
        - name: D
          dependencies: [B, C]
          template: echo
    ```


## WorkflowTemplate
- Def of Workflows qui live in the cluster. 
- Lib of frequently-used templates and reuse them, by submitting them directly, or ref them from Workflows.

*P.S.* `template` (lower-case) is a task w/in a `Workflow` or (confusingly) a `WorkflowTemplate` under the field `templates`.

```
apiVersion: argoproj.io/v1alpha1
kind: WorkflowTemplate
metadata:
  name: wftmpl-1
spec:
  templates:
    - name: tmp-1
      container:
        image: busybox
        command: [echo]
        args: ["{{workflow.parameters.global-parameter}}"]
---
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: wf-global-arg-
spec:
  entrypoint: print-message
  arguments:
    parameters:
      - name: global-parameter
        value: hello
  templates:
    - name: print-message
      steps:
        - - name: hello-world
            templateRef:
              name: wftmpl-1  # ref to WorkflowTemplate
              template: tmp-1 # ref to template
```

### Create `Workflow` from `WorkflowTemplate` Spec
- WorkflowTemplate qua menu, Workflow qua order
- Override / customise Workflow (order) into WorkflowTemplate (menu)

```
kind: Workflow
...
spec:
  entrypoint: print-message
  arguments:
    parameters:
      - name: message
        value: "from workflow"
  workflowTemplateRef:
    name: workflow-template-submittable
```

### WrokflowTemplate Mgmt
CLI
```
argo template create <templates.yml> # create WorkflowTemplate
argo submit --from <templates.yml> # submit WorkflowTemplate qua Workflow
argo submit --from <templates.yml> -p message=value1 # submit WorkflowTemplate qua Workflow w/ params
```

UI
- Spec options under `enum` field to enable drop-down list selection when submitting WorkflowTemplates from the UI.
```
kind: WorkflowTemplate
metadata:
  name: workflow-template-with-enum-values
spec:
  entrypoint: argosay
  arguments:
    parameters:
      - name: message
        value: one
        enum: # spec opts 
          -   one
          -   two
          -   three
  templates:
    - name: argosay
      inputs:
        parameters:
          - name: message # param
            value: '{{workflow.parameters.message}}'
      container: ...
```

### `ClusterWorkflowTemplates`
- Cluster wide WrokflowTemplate
- Mgmt: `argo cluster-template create <cluster-wftmpl.yml>

## `data` Template: Data Sourcing & Transformation
```
- name: generate-artifacts
  data:
    source:             
      artifactPaths: # A pre-def source: Generate a list of all artifact paths in a given repo
        s3:
          bucket: test
          endpoint: minio:9000
          insecure: true
          accessKeySecret:
            name: my-minio-cred
            key: accesskey
          secretKeySecret:
            name: my-minio-cred
            key: secretkey
    transformation:     # Source passed to transformation def. here
      - expression: "filter(data, {# endsWith \".pdf\"})"
      - expression: "map(data, {# + \".ready\"})"
```

## Access Control
### Service Account
- Map a service account to a role, or permission
```
kubectl create serviceaccount <argo-workflow>
kubectl create rolebinding <role-binding-name> --serviceaccount=argo:<argo-workflow> --role=workflow-role
argo submit --serviceaccount <argo-workflow> 
```

### RBAC
Pods in WF run w/ the service account, spec.in `workflow.spec.serviceAccountName`

## Artifact
### Input
- WF provides args, pass to entry point template.
- `template` def inputs, provided by template callers: `steps`, `dag`, `workflow`

`inputs.yml`
WF input: `spec.arguments.parameters` list
DAG input: `dag.tasks.<task>.arguments.parameters`, incl. `name`, `value`. DAG has a list of tasks
Template input: `inputs.parameters` list
```
kind: Workflow
sepc:
  arguments: # WF inputs
    parameters:
    - name: workflow-param-1

  templates:

  - name: main
    dag: # DAG input
      tasks:
      - name: step-A 
        template: step-template-a
        arguments:
          parameters:
          - name: template-param-1
            value: "{{workflow.parameters.workflow-param-1}}" # ref to workflow param

  - name: step-template-a
    inputs:
      parameters:
        - name: template-param-1
    ...
```

```
argo submit -n argo inputs.yml -p 'workflow-param-1="foo"' --watch
```

#### Output of prev. step qua input
```
dag:
  tasks:
  - name: step-A 
    template: step-template-a
    arguments:
      parameters:
      - name: template-param-1
        value: "{{workflow.parameters.workflow-param-1}}"
    outputs:
      parameters:
        - name: output-param-1
          valueFrom:
            path: /file.txt
      artifacts:
        - name: output-artifact-1
          path: /some-dir

  - name: step-B
    dependencies: [step-A]
    template: step-template-b
    arguments:
      parameters:
      - name: template-param-2
        value: "{{tasks.step-A.outputs.parameters.output-param-1}}" # parameters use value
      artifacts:
      - name: input-artifact-1
        from: "{{tasks.step-A.outputs.artifacts.output-artifact-1}}" # artifacts use from
```

### Key-only Artifact
- only spec the key for I/O artifact, omitting bucket, secrets etc.
- default from v3.0

```
outputs:
  artifacts:
    - name: file
      path: /mnt/file
      s3:
        key: my-file

inputs:
  artifacts:
    - name: file
      path: /tmp/file
      s3:
        key: my-file
```
### Artifact Repo Ref
- Config artifact repo, where large files are stored. 
- Remove duplication & sensitives in templates config.
- `ConfigMap` in WF or mng ns.

```
kind: ConfigMap
metadata:
  # name: "artifact-repositories" for default ConfigMap.
  # Ref ConfigMap/Artifact Repo: `artifactRepositoryRef.configMap`
  name: custom-artifact-repository
  annotations:
    # Put the key into annotation for spec. key
    workflows.argoproj.io/default-artifact-repository: default-v1-s3-artifact-repository
data:
  default-v1-s3-artifact-repository: |
    s3:
      bucket: my-bucket
      endpoint: minio:9000
      insecure: true
      accessKeySecret:
        name: my-minio-cred
        key: accesskey
      secretKeySecret:
        name: my-minio-cred
        key: secretkey
```

`workflow.yml`
```
kind: Workflow
spec:
  artifactRepositoryRef:
    configMap: custom-artifact-repository # default: artifact-repositories
    key: default-v1-s3-artifact-repository
```

### Cond. Artifact & Param
```
- name: coinflip
  steps:
    - - name: flip-coin
        template: flip-coin
    - - name: heads
        template: heads
        when: "{{steps.flip-coin.outputs.result}} == heads"
      - name: tails
        template: tails
        when: "{{steps.flip-coin.outputs.result}} == tails"
  outputs:
    artifacts:
      - name: result
        fromExpression: "steps['flip-coin'].outputs.result == 'heads' ? steps.heads.outputs.artifacts.headsresult : steps.tails.outputs.artifacts.tailsresult"

    parameters:
    - name: stepresult
      valueFrom:
        expression: "steps['flip-coin'].outputs.result == 'heads' ? steps.heads.outputs.result : steps.tails.outputs.result"
```

## Retry
Works mostly on `container`, `script`

`retryPolicy`
- OnFailure: default, main container marked as failed in K8s. No need to spec `retryPolicy`, but still need to spec `retryStrategy`.
- Always: retry all failed steps.
- OnError: encounter Argo controller errors, init / wait containers fail
- OnTransientError: ex vi termini


```
templates:
- name: retry-container
  retryStrategy:
    limit: "2" # retry fois
    retryPolicy: "Always"
    expression: 'lastRetry.status != "Error" || asInt(lastRetry.duration) < 60'
    backoff:
      duration: "2m" # wait 2m before retry
      factor: 2 # 1e retry wait 2m. 2e wait 4m...
  container:
    image: python
    commad: ...
``` 

## Lifecycle-Hook
- Trigger an action given cond.: cond expr, completion of template.
- Workflow or template lvl
- Exit handler w/ cond.
> Exit handler qua template, will exec no matter the outcome
> Ref: spec.onExit

Workflow lvl
```
spec:
  hooks:
    exit: # Exit handler
      template: http
    running:
      expression: workflow.status == "Running"
      template: http
```

Template lvl
```
templates:
  - name: step-1
    hooks:
      running: # hook name doesn't matter
        expression: steps["step-1"].status == "Running"
        template: http
      success:
        expression: steps["step-1"].status == "Succeeded"
        template: http
    template: echo
```

## Sync
- Mutex: restrict WF / Template have 1 concurrent exec
- Semaphore: #parallelism, use `ConfigMap`

Mutex:
```
spec: # WF lvl
  synchronization:
    mutexes:
      - name: bar
```


### Multi-Controller Semaphores
- Lock (semaphore) share inter-controller
- Semaphores stored in DB: `INSERT INTO sync_limit (name, sizelimit) VALUES ('ns/name', 3);`

Semaphore
```
apiVersion: v1
kind: ConfigMap
metadata:
 name: custom-config
data:
  workflow: "1"  # 1 WF can run atm in the ns where ConfigMap is deployed, label is arbitrary
  template: "2"  # 2 inst of Template can run atm in the ns

---

kind: Workflow
metadata:
  generatedName: sync-wf-lvl-
  namespace: foo
spec:
  synchronization:
    semaphores:
      - configMapKeyRef:
          key: bar
          name: custom-config

      # multi-controller semaphore
      - database:
          key: <semaphore> 
```