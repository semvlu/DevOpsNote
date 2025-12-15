docker network create <network-name>
docker network rm  <network-name>

# container conn. to user-def brdige net
docker create --name <container> \
    --network <network-name> \
    --publish <host-port>:<container-port>


docker network connect/disconnect <network-name> <container>

# Host Network: container on the port of Host IP
:'
Scenario: 
    1. optm performance 
    2. container needs to handle many ports.
'
docker run --rm -it --net=host nicolaka/netshoot nc -lkv 0.0.0.0 8000

# IPvlan: control over IP addrssing: l2 (default), l3, l3s
docker network create -d ipvlan \
    --subnet=<subnet> \
    --gateway=<gateway> \
    -o ipvlan_mode=l2 \
    -o parent=<parent_intf> <network-name>
# -d: driver

# IPvlan L3
# Scenario: massive scale, migration
# Containers can ping each other w/o Router if share the same parent intf 
docker network create -d ipvlan \
    --subnet=<subnet> \
    --subnet=<subnet> \
    -o ipvlan_mode=l3 <network-name>
# docker assign container to the first subnet by default, custom by:
docker run -d --net <network-name> --ip <ip> <img> 

# Overlay: containers on 1+ machines
# Windows NOT supported
docker network create -d overlay <network-name>
docker service create \
  --name my-nginx \
  --network my-overlay \
  --replicas 1 \
  --publish published=8080,target=80 \
  nginx:latest

