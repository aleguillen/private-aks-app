#cloud-config
package_upgrade: true
packages:
  - curl
  - unzip

runcmd:
 #
 # Create Folder under Home/User directory
 #
 - mkdir azagent; cd azagent
 - echo "[$(date +%F_%T)] $(pwd)" # >> ./ado_cloud_init.log
 - echo "[$(date +%F_%T)] Starting cloud_init script" # >> ./ado_cloud_init.log
 #
 # Downloding and installing VSTS agent package
 #
 - echo "[$(date +%F_%T)] Downloading Agent"
 - curl -fkSL -o vsts-agent.tar.gz https://vstsagentpackage.azureedge.net/agent/2.164.8/vsts-agent-linux-x64-2.164.8.tar.gz
 - echo "[$(date +%F_%T)] Extracting Agent"
 - tar -zxvf vsts-agent.tar.gz 
 - echo "[$(date +%F_%T)] Running installdependencies.sh"
 - ./bin/installdependencies.sh
 - echo "[$(date +%F_%T)] Running config.sh"
 - ./config.sh --unattended --url "${server_url}" --auth pat --token "${pat_token}" --pool "${pool_name}" --agent $HOSTNAME --work _work --acceptTeeEula
 - echo "[$(date +%F_%T)] Running scv.sh"
 - sudo ./svc.sh install
 - sudo ./svc.sh start
 #
 # Install Azure CLI Deb
 #
 - echo "[$(date +%F_%T)] Installing Azure CLI"
 - curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
 #
 # Install Docker
 #
 - echo "[$(date +%F_%T)] Installing Docker"
 - sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
 - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
 - sudo apt-key fingerprint 0EBFCD88
 - sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs)  stable"
 - sudo usermod -aG docker $USER
 - sudo systemctl enable docker
 - sudo systemctl start docker
 #
 # Install Docker Compose
 #
 - echo "[$(date +%F_%T)] Installing Docker Compose"
 - sudo curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
 - sudo chmod +x /usr/local/bin/docker-compose

power_state:
 delay: "+1"
 mode: reboot
 message: Rebooting after ADO configuration
 timeout: 30
 condition: True