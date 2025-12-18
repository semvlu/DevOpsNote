docker run -d -p 8080:80 --name webserver nginx
# IMAGE = nginx
# docker container run [OPTIONS] IMAGE [COMMAND] [ARG...]

docker container exec -it webserver bash
# attach prog (e.g. bash) to the container (e.g. webserver)
docker stop webserver 
docker rm webserver # remove container from mem
docker rmi nginx # remove img

docker logs <container>

#---------------------------------------------------------
docker build .  # build 
docker tag <tagID> usr/repos:tagName # tagID is gen from build cmd, tagName = verName
docker push usr/repos:tagName
#---------------------------------------------------------


# -------------------Run private registry w/ TLS --------------------
# gen SSL cert
mkdir -p certs
openssl req -newkey rsa:4096 -nodes -sha256 \
-keyout certs/domain.key -x509 -days 365 -out certs/domain.crt

docker-compose up -d



# alias, optional
# bind to localhost
alias composer="docker run -it --rm -v $(pwd):/<dirInContainer>"
:'
 $(pwd): current working dir
--rm: Automatically remove container & associated anonymous volumes when exit
-v: bind mount a volume
'

# Volume
docker volume create myvol
docker run -d --name cont4VolTest -v myvol:./app # containerName = cont4VolTest


# On docker client, copy CA cert
mkdir -p /etc/docker/certs.d/your-registry-domain:5000
cp certs/domain.crt /etc/docker/certs.d/your-registry-domain:5000/ca.crt


# tag / push / pull
docker tag <image> <registry-domain>:5000/<image>
docker push <registry-domain>:5000/<image>
docker pull <registry-domain>:5000/<image>
# <image> := usr/repos:tagName

# -------------------------------------------------------------------

