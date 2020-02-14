#!/bin/bash

function log()
{
  echo "[$(date +%F_%T)] $1" >> /tmp/ado_cloud_init.log
}

log "Starting cloud_init script"

log "Current path: $(pwd)"

log "Creating Directory: azagent"
mkdir azagent

log "Creating ado_config.sh script local"

{
cat <<-"EOF"  > ./azagent/ado_config.sh
#!/bin/bash

sudo apt-get update
sudo apt install curl -y
sudo apt install unzip -y

cd azagent

curl -fkSL -o vsts-agent.tar.gz https://vstsagentpackage.azureedge.net/agent/2.164.8/vsts-agent-linux-x64-2.164.8.tar.gz

sudo chmod o+w -R /azagent/

sudo ./bin/installdependencies.sh

./config.sh --unattended  --url "${server_url}" --auth pat --token "${pat_token}" --pool "${pool_name}" --agent $HOSTNAME --work _work --acceptTeeEula

sudo ./svc.sh install

sudo ./svc.sh start

sudo ./svc.sh status

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs)  stable"

sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo usermod -aG docker $USER

# Auto-start on boot
sudo systemctl enable docker

# Start right now 
sudo systemctl start docker 

sudo curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

sudo reboot

EOF
} 2>&1 | tee -a /tmp/ado_cloud_init.log

log "Running of cloud_init script: $(pwd)/azagent/ado_config.sh"
log "Running as root"

cd azagent
log "Setting permissions"
sudo chmod o+x -R ./

log "Running ado_config.sh"
sh ./ado_config.sh >> /tmp/ado_config.log 2>&1 

log "End of cloud_init script"