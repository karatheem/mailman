# Creating a common VNET network environment for Azure VM and AKS

# Setting variables
timestamp=$(date '+%Y/%m/%d-%H:%M UTC%z')
suffix=$((10000 + RANDOM % 99999))
RG="mailman" # Name of resource group for the AKS cluster
location="uksouth" # Name of the location 
AKS="aks-azurecni-$suffix" # Name of the AKS cluster

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
subnetIdvm=$(az network vnet subnet show --resource-group $RG --vnet-name mailnet --name vm_subnet --query id -o tsv)# Create the complete mailman server environment deployment script
echo ""
sleep 2

echo "The AKS cluster: "
az aks create --resource-group $RG --name $AKS --node-count 1 --network-plugin azure --vnet-subnet-id $subnetId --enable-aad --generate-ssh-keys
sleep -Seconds 5

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
read -n 1 -srp "Press any key to continue..." && echo ""
