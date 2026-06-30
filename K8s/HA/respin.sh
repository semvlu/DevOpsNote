# After haproxy.cfg modification, run
mv /etc/kubernetes/manifests/haproxy.yaml /tmp/
sleep 10
mv /tmp/haproxy.yaml /etc/kubernetes/manifests/

kubectl patch deploy rancher -n cattle-system \
  -p '{"spec": {"template": {"spec": {"containers": [{"name": "rancher", "startupProbe": {"failureThreshold": 300}}]}}}}'
