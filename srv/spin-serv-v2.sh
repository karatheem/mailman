# Create the complete mailman server environment deployment script

RG="mailman" # Name of resource group for the AKS cluster
location="uksouth" # Name of the location 

#########A################################################################################################## -> VNET
# Creating a common VNET network environment for Azure VM and AKS

# Setting variables
timestamp=$(date '+%Y/%m/%d-%H:%M UTC%z')
suffix=$((10000 + RANDOM % 99999))

az group create -n $RG -l $location
echo ""

# Create virtual network and subnets
echo "The BYO VNET: "
az network vnet create --resource-group $RG --name mailnet --address-prefixes 10.0.0.0/8 --subnet-name aks_subnet --subnet-prefix 10.240.0.0/16

echo ""
echo "The BYO VNET subnet: "

az network vnet subnet create --resource-group $RG --vnet-name mailnet --name vm_subnet --address-prefixes 10.241.0.0/16

# save subnets as ids
subnetId=$(az network vnet subnet show --resource-group $RG --vnet-name mailnet --name aks_subnet --query id -o tsv)
subnetIdvm=$(az network vnet subnet show --resource-group $RG --vnet-name mailnet --name vm_subnet --query id -o tsv)
echo ""
sleep 2

#########A################################################################################################## -> ACR

echo "Creating an Azure Container Registry (ACR)"
sleep 1

# Setting variables
timestamp=$(date '+%Y/%m/%d-%H:%M UTC%z')
suffix=$((10000 + RANDOM % 99999))
acr="publicacr${suffix}"
acrpath=$acr.azurecr.io

# Create the ACR resource
az acr create -n $acr -g $RG --sku Standard

# Login to ACR in azcli shell
# az acr login --name $acr

# Add a basic image to the repository for testing
# az acr import -n $acr --source docker.io/library/hello-world:latest -t $acrpath:test1

#########A################################################################################################## -> Managed ID

managed_id="acr-managed-id-$suffix"

# Create a managed identity for the ACR
az identity create --name $managed_id --resource-group $RG --location $location

echo "Wait for managed ID propagation" 
sleep 10

# Get the Resource ID, Principal ID and ACR ID
resource_id=$(az identity show --name $managed_id --resource-group $RG --query id --output tsv)
principal_id=$(az identity show --name $managed_id --resource-group $RG --query principalId -o tsv)
acr_id=$(az acr show --name $acr --resource-group $RG --query id --output tsv)

# Create rolebind

az role assignment create --assignee $principal_id --role AcrPull --scope $acr_id

#########A################################################################################################## -> AKS

AKS="aks-azurecni-$suffix" # Name of the AKS cluster

echo "The AKS cluster: "
az aks create --resource-group $RG --name $AKS --node-count 1 --network-plugin azure --vnet-subnet-id $subnetId --enable-aad --generate-ssh-keys --assign-identity $resource_id --attach-acr $acr
sleep 5



echo ""
sleep 1

#echo "Configuring kubectl to connect to the Kubernetes cluster"
# echo "If you want to connect to the cluster to run commands, run the following:"
# az aks get-credentials --resource-group $RG --name $AKS --admin --overwrite-existing
#az aks get-credentials --resource-group $RG --name $AKS --admin --overwrite-existing
#echo "You should be able to run kubectl commands to your cluster now"
#echo ""
#echo "Install kubectl locally, if needed: az aks install-cli"
#echo ""

#########A################################################################################################## -> VM

echo "Creating an Azure VM running Ubuntu2204"
sleep 1

# Setting variables
timestamp=$(date '+%Y/%m/%d-%H:%M UTC%z')
suffix=$((10000 + RANDOM % 99999))
VM="mailman-ubuntu-$suffix"
image="Ubuntu2204"
NSG=${VM}NSG

# Generating a random string to use as password
userName="postman"
#$randompass = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 30 | ForEach-Object {[char]$_})
#Read more: https://www.sharepointdiary.com/2020/04/powershell-generate-random-password.html#ixzz8XiwccFos
#$Password = ConvertTo-SecureString $randompass -AsPlainText -Force
#$psCred = New-Object System.Management.Automation.PSCredential($UserName, $Password)
sleep 1
echo ""

# Create Ubuntu VM
echo "Creating virtual machine $VM in resource group $RG in location $location"
az vm create -n $VM -g $RG --image $image --generate-ssh-keys --admin-username $userName --size Standard_D2s_v3 --nsg-rule ssh --public-ip-sku Standard --subnet $subnetIdvm

# Add NSG rule to allow inbound and outbound on designated port
az network nsg rule create -g $RG --nsg-name $NSG -n Allow8080 --priority 4096 --destination-port-ranges 8080 --access Allow --protocol Tcp --description "Allow 8080."

sleep 2

# Add system-assigned managed ID to the VM
az vm identity assign -g $RG -n $VM

sleep 10

# Get the VM principal ID and assign the ACR Push role for image upload
vm_principal_id=$(az vm identity show -g $RG -n $VM --query principalId -o tsv)
az role assignment create --assignee $vm_principal_id --role AcrPush --scope $acr_id

sleep 10

# Get AKS ID and assign it Azure Kubernetes Service Cluster Admin Role
aks_id=$(az aks show -g $RG -n $AKS --query id -o tsv)
az role assignment create --assignee $vm_principal_id --role "Azure Kubernetes Service Cluster Admin Role" --scope $aks_id

# This is the public IP address
# $vmip=$(az vm list-ip-addresses -g $rg -n $vmName --query "[].virtualMachine.network.publicIpAddresses[0].ipAddress" --output tsv)
vmip=$(az vm list-ip-addresses -g $RG -n $VM --query "[].virtualMachine.network.publicIpAddresses[0].ipAddress" --output tsv)

sleep 1
echo ""
echo "The public IP address allocated to VM $VM is $vmip"
echo "Save aside your credentials"
echo "The admin user name is: ${userName}"
echo ""
sleep 1

# Run the docker install script commands inside the VM
az vm run-command create --resource-group $RG --async-execution false --run-as-user $userName --script "export acr=$acr; export AKS=$AKS; export RG=$RG; sudo wget -O - https://raw.githubusercontent.com/karatheem/mailman/refs/heads/progress/srv/spin-vm-guest.sh | bash" --timeout-in-seconds 3600 --run-command-name "SetDockerUp" --vm-name $VM

# Look for user input to perform ssh connection right now
read -p "Do you want to connect to ${VM} via ssh now? (y/n) " userinput
if [ "$userinput" = "y" ]; then
    az ssh vm -g "$RG" -n "$VM" --local-user "$userName" --yes
else
    echo "Save the command for later: az ssh vm -g $RG -n $VM --local-user $userName"
fi

read -n 1 -srp "Press any key to continue..." && echo ""
