# Instance type: m6a.xlarge (vcpu 4/16 GiB ram)
# Operating System: Ubuntu 22.04
# Disk Storage 100 Gib SSD

echo "##################################################################"
echo "# Script: Setup observability instance SME Obs 2                 #"
echo "# Description: To create a observability instance for SME Obs 2. #"
echo "# Created date: 20/10/26                                         #"
echo "# Arthur: Alex J Davison (alexdav@cisco.com)                     #"
echo "# Version: 2.0.0                                                 #"
echo "# Starting...                                                    #"
echo "##################################################################"
echo ""
echo "#############"
echo "# Update OS #"
echo "#############"
echo ""
echo "Step 1/1: Downloads the package lists from the repositories and "updates" them to get information on the newest versions of packages and their dependencies."
sudo apt-get update
echo ""
echo "#####################"
echo "# Update Networking #"
echo "#####################"
echo ""
echo "Step 1/10: Get IP values"
sudo resolvectl >> ip.log
echo "Step 3/10: Find DNS servers"
cat ip.log | grep "DNS Servers: " * > dns.log
echo "Step 4/10: Remove IP values file"
rm ip.log
echo "Step 5/10: Load DNS values into memory"
dnsvalue=`cat dns.log`
echo "Step 6/10: Trim crap"
dnsvalue=${dnsvalue:27}
echo "Step 7/10: Write new trimmed DNS values"
echo $dnsvalue >> new_dns.log
echo "Step 8/10: Remove DNS values file"
rm dns.log
echo "Step 9/10: Format DNS servers"
sed -i 's/ /,/g' new_dns.log
echo "Step 10/10: Load new DNS values"
cat new_dns.log
dnsvalue=`cat new_dns.log`
echo "Step 11/10: Clean up"
rm new_dns.log
echo ""
echo "####################"
echo "# Install microk8s #"
echo "####################"
echo ""
echo "Step 1/5: Install microk8s"
sudo snap install microk8s --classic --channel=1.25/stable
echo "Step 2/5: Create group"
sudo usermod -a -G microk8s $USER
echo "Step 3/5: Make directory"
sudo mkdir -p ~/.kube
echo "Step 4/5: Change permission on folder"
sudo chmod 0700 ~/.kube
echo "Step 5/5: Enable features for microk8s"
sudo microk8s enable dns:$dnsvalue 
sudo microk8s enable rbac 
sudo microk8s enable hostpath-storage 
sudo microk8s enable ingress 
sudo microk8s enable cert-manager 
sudo microk8s enable dashboard 
sudo microk8s enable istio 
sudo microk8s enable registry
echo ""
echo "##########################"
echo "# Creates microk8s alias #"
echo "##########################"
echo ""
echo "Step 1/3: Add helm alias"
echo 'alias helm=microk8s.helm' | sudo tee -a  /etc/bash.bashrc
echo "Step 2/3: Add kubectl alias"
echo 'alias kubectl=microk8s.kubectl' | sudo tee -a  /etc/bash.bashrc
echo "Step 3/3: Load alias"
. /etc/bash.bashrc
echo ""
echo "##########################"
echo "# Setups microk8s config #"
echo "##########################"
echo ""
echo "Step 1/5: Going home"
cd $HOME
echo "Step 2/5: Create folder"
sudo mkdir .kube
echo "Step 3/5: Go in new folder"
cd .kube
echo "Step 4/5: Export config"
sudo microk8s config >> config
echo "Step 5/5: Go home"
cd $HOME
echo ""
echo "######################"
echo "# Download helm repo #"
echo "######################"
echo ""
echo "Step 1/2: Adding otel collector"
sudo microk8s helm repo add splunk-otel-collector-chart https://signalfx.github.io/splunk-otel-collector-chart
echo "Step 2/2: Updating helm repos"
sudo microk8s helm repo update
echo ""
echo "#####################"
echo "# Setup Splunk Otel #"
echo "#####################"
echo ""
echo "Step 1/2: Create otel namespace"
sudo microk8s kubectl create ns otel
echo "Step 2/2: Install new config to namespace splunkotel"
sudo microk8s helm -n otel install splunk-otel-collector --values ./obs-sme2/SMEObs2.yaml splunk-otel-collector-chart/splunk-otel-collector
echo ""
echo "################"
echo "# Pacman Repo #"
echo "################"
echo ""
echo "Step 1/1: Clone repo for pacman"
sudo git clone https://github.com/splunk/pacman.git
echo ""
sudo microk8s kubectl create ns pacman
echo ""
echo "##########"
echo "# Docker #"
echo "##########"
echo ""
echo "Step 1/22: Downloads the package lists from the repositories and "updates" them to get information on the newest versions of packages and their dependencies."
sudo apt-get update
echo "Step 2/22: Setup certificates"
sudo apt install ca-certificates curl
echo "Step 3/22: Add Docker's official GPG key"
sudo install -m 0755 -d /etc/apt/keyrings
echo "Step 4/22: Add Docker's official GPG key"
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "Step 5/22: Add Docker's official GPG key"
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "Step 6/22: Add the repository to Apt sources"
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
echo "Step 7/22: Downloads the package lists from the repositories and "updates" them to get information on the newest versions of packages and their dependencies."
sudo apt update
echo "Step 8/22: Install docker"
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo "Step 9/22: Stop docker"
sudo systemctl stop docker
echo "Step 10/22: Stop containerd"
sudo systemctl stop containerd
echo "Step 11/22: Clean up snapshotter"
sudo rm -rf /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/*
echo "Step 12/22: Start containerd"
sudo systemctl start containerd
echo "Step 13/22: Start docker"
sudo systemctl start docker
echo "Step 14/22: Ensure correct repo"
apt-cache madison containerd.io
echo "Step 15/22: Install fuse overlay fsß"
sudo apt install fuse-overlayfs
echo "Step 16/22: Make directory /etc/docker"
sudo mkdir -p /etc/docker
echo "Step 17/22: Set storage path"
sudo echo '{ "storage-driver": "fuse-overlayfs" }' | sudo tee /etc/docker/daemon.json
echo "Step 18/22: Restart docker"
sudo systemctl restart docker
echo "Step 19/22: Build docker pacman image"
sudo docker build --no-cache -t pacman:latest -f  pacman/docker/Dockerfile pacman
echo "Step 20/22: List docker images"
sudo docker images
echo "Step 21/22: Export pacman from docker"
sudo docker save pacman:latest > pacman.tar
echo "Step 22/22: Import pacman into microk8s"
sudo microk8s ctr image import pacman.tar
echo ""
echo "################"
echo "# Verification #"
echo "################"
echo ""
echo "Step 1/2: Wait before checking"
total_seconds=60
while [ $total_seconds -gt 0 ]; do
    printf "Time remaining: %d seconds\r" "$total_seconds"
    sleep 1
    total_seconds=$((total_seconds - 1))
done
echo ""
echo "Step 2/2: Status"
sudo microk8s kubectl get all --all-namespaces



## import docker image into micrk8s registry
## docker save pacman:latest |  /snap/bin/microk8s ctr image import -
## sudo microk8s helm -n pacman install --values ./pacman/kubernetes/k8s.yaml
## sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
## import docker image into micrk8s registry
## docker save pacman:latest |  /snap/bin/microk8s ctr image import -