# Instance type: m5/xlarge (vcpu 4 / 16 GiB ram)
# Operating System: Ubuntu 20.04
# Disk Storage 100 Gib SSD

echo "###############################################################"
echo "# Script: Step-1 Setup observability instance                 #"
echo "# Description: To create a observability instance.            #"
echo "# Created date: 09/09/26                                      #"
echo "# Arthur: Alex J Davison (alexdav@cisco.com)                  #"
echo "# Version: 1.0.0                                              #"
echo "# Starting...                                                 #"
echo "###############################################################"
echo ""
echo "#############"
echo "# Update OS #"
echo "#############"
echo ""
echo "Step 1/11: Updating OS"
sudo apt-get update
echo "Step 2/11: Get IP values"
sudo resolvectl >> ip.log
echo "Step 3/11: Find DNS servers"
cat ip.log | grep "DNS Servers: " * > dns.log
echo "Step 4/11: Remove IP values file"
rm ip.log
echo "Step 5/11: Load DNS values into memory"
dnsvalue=`cat dns.log`
echo "Step 6/11: Trim crap"
dnsvalue=${dnsvalue:27}
echo "Step 7/11: Write new trimmed DNS values"
echo $dnsvalue >> new_dns.log
echo "Step 8/11: Remove DNS values file"
rm dns.log
echo "Step 9/11: Format DNS servers"
sed -i 's/ /,/g' new_dns.log
echo "Step 10/11: Load new DNS values"
cat new_dns.log
dnsvalue=`cat new_dns.log`
echo "Step 11/11: Clean up"
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
chmod 0700 ~/.kube
echo "Step 5/5: Enable features for microk8s"
sudo microk8s enable dns:$dnsvalue rbac hostpath-storage ingress cert-manager dashboard istio registry
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
echo "Step 2/3: Adding otel collector"
sudo microk8s helm repo add splunk-otel-collector-chart https://signalfx.github.io/splunk-otel-collector-chart
echo "Step 3/4: Updating helm repos"
sudo microk8s helm repo update
echo ""
echo "#####################"
echo "# Setup Splunk Otel #"
echo "#####################"
echo ""
echo "Step 1/2: Create otel namespace"
sudo microk8s kubectl create ns otel
echo "Step 2/2: Install new config to namespace splunkotel"
sudo microk8s helm -n otel install splunk-otel-collector --values ./SMEObs/SMEObs.yaml splunk-otel-collector-chart/splunk-otel-collector
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
echo ""