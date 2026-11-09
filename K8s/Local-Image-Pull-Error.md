# Kubernetes Unable to Pull Local Images in an Air-Gapped Environment 
- `imagePullPolicy: IfNotPresent`

`99-airgap.conf`
```yml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
imagePullCredentialsVerificationPolicy: NeverVerify
```
