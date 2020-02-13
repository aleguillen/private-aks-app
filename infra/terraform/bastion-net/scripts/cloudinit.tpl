#cloud-config
package_upgrade: true
runcmd:
 #
 # Create Folder under Home/User directory
 #
 - mkdir ~/ado_config 
 - echo "[$(date +%F_%T)] Starting cloud_init script" >> ~/ado_config/ado_cloud_init.log
 - sudo apt install curl -y
 #
 # Downloding and installing VSTS agent package
 #
 - curl -fkSL -o vsts-agent.tar.gz https://vstsagentpackage.azureedge.net/agent/2.164.8/vsts-agent-linux-x64-2.164.8.tar.gz
 - tar -zxvf vstsagent.tar.gz 
 - sudo ./bin/installdependencies.sh
 - ./config.sh --unattended --deploymentgroup --deploymentgroupname "${deployment_group_name}" --url "${server_url}" --auth pat --token "${pat_token}" --pool "${pool_name}" --agent $HOSTNAME --work _work --acceptTeeEula 
 - sudo ./svc.sh install
 - sudo ./svc.sh start
 #
 # Install Azure CLI Deb
 #
 - curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
 #
 # Install Docker
 #
 - sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
 - sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs)  stable"
 - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
 - sudo apt-key fingerprint 0EBFCD88
 - sudo usermod -aG docker $USER
 - sudo systemctl enable docker
 - sudo systemctl start docker
 #
 # Install Docker Compose
 #
 - sudo curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
 - sudo chmod +x /usr/local/bin/docker-compose

power_state:
 delay: "+30"
 mode: reboot
 message: Rebooting after ADO configuration
 timeout: 30
 condition: True