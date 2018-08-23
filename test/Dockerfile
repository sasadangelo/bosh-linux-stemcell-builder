# Download base image ubuntu 14.04.
FROM ubuntu:16.04

ARG ssh_prv_key
ARG ssh_pub_key

# Update Ubuntu Software repository. This is required to install packages.
# Install the following packages:
#     wget is required to download PoatsgreSQL
#     git is required to download selfie
#     xz-utils is required to untar tar.xz PostgreSQL package
#     openssh-server is required to access NGHA machines via ssh
RUN apt-get update && apt-get install -y wget git xz-utils openssh-server \
	systemd-services

# Create .ssh folder in /root folder in order to install SSH Keys
# that will be used to:
# 1. download selfie from github.ibm.com
# 2. connect to the three machines from the development machine
# Private key is copied in /root/.ssh/id_rsa
# Public key is copied in /root/.ssh/id_rsa.pub and will be part of authorized_keys
# These keys will be managed by ssh-agent in order to connect to github.ibm.com
# without provide any password. At the same time since the public key is one
# authorized for access to the docker container, when we ssh to it from the development
# machine providing the private key we access to the container without any password.
# These steps are critical for automation.
RUN mkdir -p /root/.ssh && \
	chmod 0700 /root/.ssh && \
	ssh-keyscan github.ibm.com > /root/.ssh/known_hosts
RUN echo "$ssh_prv_key" > /root/.ssh/id_rsa && \
	echo "$ssh_pub_key" > /root/.ssh/id_rsa.pub && \
	echo "$ssh_pub_key" > /root/.ssh/authorized_keys && \
	chmod 600 /root/.ssh/id_rsa && \
	chmod 600 /root/.ssh/id_rsa.pub && \
	chmod 600 /root/.ssh/authorized_keys
RUN env=~/.ssh/agent.env; umask 077; ssh-agent > "$env"; . "$env"; ssh-add ~/.ssh/id_rsa

# Start ssh and dbus daemon at container boot
ENTRYPOINT service ssh start && /bin/bash
EXPOSE 22
