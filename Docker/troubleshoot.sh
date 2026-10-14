# Host Port Inaccessible after Container Restart
nft list ruleset | grep -E "<port>|podman|docker|netavark"
systemctl restart <docker | podman>
firewall-cmd --reload
ufw reload
