# Identity file
#PRIVATE_KEY_FILE="~/.ssh/id_rsa_docker"

# Make source code visible in the containers
MOUNT_FOLDER=/Users/sasadangelo/github.com/bluebosh/bosh-linux-stemcell-builder

# Machines private names
STEMCELL1_PRIVATE_NAME=stemcell1

# Machines private ips
STEMCELL1_PRIVATE_IP=10.0.3.41

# Machines ssh port
STEMCELL1_SSH_PORT=5551

# Docker network names
PRIVATE_NETWORK_NAME=stemcell_private_bridge

# Create a public and private network
docker network create -d bridge --gateway=10.0.3.1 --subnet=10.0.3.1/24 ${PRIVATE_NETWORK_NAME}

# Create the container and associate it to the network
docker create -it --net ${PRIVATE_NETWORK_NAME} --publish ${STEMCELL1_SSH_PORT}:22 --ip ${STEMCELL1_PRIVATE_IP} --name ${STEMCELL1_PRIVATE_NAME} --hostname ${STEMCELL1_PRIVATE_NAME} -v ${MOUNT_FOLDER}:/Users stemcell /bin/bash

# Start the container. By default they will be started in detached mode. This means
# the container is started and prompt is returned immediately. Container will not
# die because ENTRYPOINT in Dockerfile run the /bin/bash shell that never return.
docker start ${STEMCELL1_PRIVATE_NAME}
