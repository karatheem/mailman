# Creating a common VNET network environment for Azure VM and AKS

# Setting variables
timestamp=$(date '+%Y/%m/%d-%H:%M UTC%z')
suffix=$((10000 + RANDOM % 99999))
RG="mailman" # Name of resource group for the AKS cluster
location="uksouth" # Name of the location 

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

