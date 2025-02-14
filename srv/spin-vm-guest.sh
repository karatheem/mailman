# Code to run inside the VM to have the setup ready

# Add Docker's official GPG key:
sudo apt-get update 
sudo apt-get install -y ca-certificates curl apt-transport-https gnupg git
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sleep 2

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sleep 2

# Install the docker packages
echo "Now installing the docker packages"
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin --yes
sleep 2

# Add user to docker group
sudo usermod -aG docker $USER

# Run the test hello world
echo "Let's test it with a quick hello-world container"
sudo docker run hello-world
sleep 2

# Install Node.js to host the web content
sudo apt-get install -y nodejs npm

# Install Azure-CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Cloning mailman repo
HOME_DIR="/home/$USER"
git clone https://github.com/karatheem/mailman/ $HOME_DIR/mailman

#Commenting everything out from here on out since the repo folder doesn't show up anymore
#npm install $HOME_DIR/mailman/client/

# Moving Node.js service file to appropriate dir
#sudo mv $HOME_DIR/mailman/client/mailman.service /etc/systemd/system/mailman.service

# Enabling service
#sudo systemctl enable --now mailman.service

### Installing kubectl 
# Getting the public signing key to match the AKS version
#curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
#sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Adding apt repo
#echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
#sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

# Run install commands
#sudo apt-get update
#sudo apt-get install -y kubectl="1.30.9-1.1"
