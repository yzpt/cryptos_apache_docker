# Docker desktop for linux ===================================================================
# instal before classic if need desktop version !

# Download and install .deb package
# see https://docs.docker.com/desktop/install/ubuntu/

# post-installation steps:
# https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user


# Docker classic =============================================================================

# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker Packages:
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verification by running the hello-world image:
sudo docker run hello-world

#docker list images
sudo docker images

#docker list containers
sudo docker ps -a

# get the container id into a variable:
CONTAINER_ID=$(sudo docker ps -a | grep hello-world | awk '{print $1}')

# stop the container:
sudo docker rm -f $CONTAINER_ID

# stop all containers:
sudo docker rm -f $(sudo docker ps -a -q)

# docker context ls
docker context ls

# set context to desktop-linux
docker context use desktop-linux

# compose up ==============
sudo docker compose up -d
# =========================

# docker logs
sudo docker logs -f <container_id>

# stop dockr cli
sudo systemctl stop docker.service

# ====================================================================================================


# https://www.benjaminrancourt.ca/how-to-completely-uninstall-docker/

