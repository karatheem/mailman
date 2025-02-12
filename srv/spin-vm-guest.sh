# Code to run inside the VM to have the setup ready

# Add Docker's official GPG key:
sudo apt-get update 
sudo apt-get install ca-certificates curl
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

# XP
HOME_DIR="/home/$USER"
git clone https://github.com/karatheem/mailman/ $HOME_DIR/mailman
