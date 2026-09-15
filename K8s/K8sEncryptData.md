# [Encrypting Confidential Data at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)

1. Det encryption at rest enabled: `ps -aux | grep kube-api | grep "encryption-provider-config"`

## Encrypt Data

1. Gen enc key: `head -c 32 /dev/urandom | base64`
2. Enc config file: `enc.yml`

```yml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
      - configmaps
      - pandas.awesome.bears.example
    providers:
      - secretbox:
          keys:
            - name: key1
              secret: <base64-enc-key>
      - identity: {} # this fallback allows reading unencrypted secrets
                     # e.g. during initial migration
```

1. Control Plane: Mount `enc.yml` to `kube-apiserver` static pod

```sh
/etc/kubernetes/enc/enc.yml

vi /etc/kubernetes/manifests/kube-apiserver.yaml

spec.containers.command[*]:
- --encryption-provider-config=/etc/kubernetes/enc/enc.yaml

spec.containers.command[*].volumeMounts:
- name: enc
  mountPath: /etc/kubernetes/enc 
  readOnly: true

spec.volumes:
- name: enc
  hostPath:
    path: /etc/kubernetes/enc
    type: DirectoryOrCreate
```

1. Restart API server
2. Verify newly written data is encrypted

```sh
kubectl create secret generic <secret> -n default --from-literal=key1=val1
etcdctl get /registry/secrets/default/<secret> | hexdump -C
kubectl get secret <secret> -n default -o yaml
```

1. Ensure all relevant data are encrypted: `kubectl get secrets -A -o json | kubectl replace -f -`

