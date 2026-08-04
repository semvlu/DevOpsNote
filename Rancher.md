# Rancher

Kubeconfig: `kubectl` shell on env var permanently:
`cp /etc/rancher/rke2/rke2.yaml ~/.kube/config`

```sh
# Add to PATH
# helm: /usr/local/bin 
# kubectl & crictl: /var/lib/rancher/rke2/bin
export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/var/lib/rancher/rke2/bin"

# crictl
export CONTAINER_RUNTIME_ENDPOINT=unix:///run/k3s/containerd/containerd.sock

```

## Config Filepath

RKE2 node: `/etc/rancher/rke2/config.yaml`
RKE2 data: `/var/lib/rancher/rke2/`
logs: `/var/log/rancher/`
etcd: `/var/lib/rancher/rke2/server/db/`

```sh
systemctl status rke2-server # Master
systemctl status rke2-agent # Worker
journalctl -u rke2-server -f
```



## Rancher Backups

Rancher app backup, not etcd (cluster). 

### Resource Sets

- Basic: Users, Clusters, Roles, Settings
- Full:  ibid. + Sensitive data, e.g. Secrets, TLS certs, tokens



## Storage

StorageClass: smb allow `uid`, `gid` permission

```yml
mountOptions:
  - noperm
```



## Rancher Upgrade

```sh
helm repo update
helm get values rancher -n cattle-system -o yaml > rancher-values.yaml
helm upgrade rancher rancher-latest/rancher \
--namespace cattle-system \
--version 2.14.3 \
-f rancher-values.yaml

kubectl -n cattle-system rollout status deploy/rancher
```



# Appendix



## RKE2: Post-VM server migration. 1 Worker Internal-IP drift (162->197)

- Initial state: wk-0: 196, wk-1: 162
- Post: wk-1: 197

1. `kubectl get no -o wide`
2. `kubectl -n cattle-system logs -l app=rancher-webhook -f`: tls: failed to verify certificate: x509: certificate is valid for 127.0.0.1, ::1, 192.168.118.162, not 192.168.119.197
3. SSH to wk-1: config.yaml: node-ip: 162. Restart rke2-agent
4. `kubectl rollout restart deploy rancher rancher-webhook`
5. wk-1: `grep -rn "192.168.119.197" /var/log`: Rke2-canal "flannel.alpha.coreos.com/public-ip":"192.168.119.197"



## Rancher: add downstream cluster

- Downstream cluster node hanging post-registration
- cattle-cluster-agent: CrashLoopBackOff

1. `kubectl edit cm -n kube-system rke2-coredns-rke2-coredns`

```
hosts {
  <Rancher-Mgmt-cluster-CP-IP> rancher.local.demo
  fallthrough
}
```

1. `kubectl rollout restart deploy rke2-coredns-rke2-coredns` 
2. `kubectl delete pod -l app=cattle-cluster-agent -n cattle-system`

