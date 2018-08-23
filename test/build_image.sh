# Private and Public keys injected in the image's ~/.ssh/ folder in order to
# download selfie from github.ibm.com and access to the machines via ssh.
PRIVATE_KEY=$(cat ~/.ssh/id_rsa_docker)
PUBLIC_KEY=$(cat ~/.ssh/id_rsa_docker.pub)

# Create the OS image that will be used by all containers as starting point.
docker build -t stemcell \
  --build-arg ssh_prv_key="$PRIVATE_KEY" \
  --build-arg ssh_pub_key="$PUBLIC_KEY" .
