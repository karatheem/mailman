echo "Creating an Azure Container Registry (ACR)"
sleep 1

# Setting variables
timestamp=$(date '+%Y/%m/%d-%H:%M UTC%z')
scenario="azacr-public"
suffix=$((10000 + RANDOM % 99999))
rg="mailman"
location="uksouth"
acr="azacr-public-$suffix"
acrpath=$acr.azurecr.io

# Create the ACR resource
az acr create -n $acr -g $rg --sku Standard

# Login to ACR in azcli shell
# az acr login --name $acr

# Add a basic image to the repository for testing
# az acr import -n $acr --source docker.io/library/hello-world:latest -t $acrpath:test1
