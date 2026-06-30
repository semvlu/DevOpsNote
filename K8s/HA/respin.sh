# After haproxy.cfg modification, run
mv /etc/kubernetes/manifests/haproxy.yaml /tmp/
sleep 10
mv /tmp/haproxy.yaml /etc/kubernetes/manifests/
