# code credits: https://github.com/marianleica/azrez
# need to change values to match current project like resource group or vm name

echo "Creating an Azure VM running Ubuntu2204"
sleep 1

# Setting variables
timestamp=$(date '+%Y/%m/%d-%H:%M UTC%z')
scenario="azvm-ubuntu2204ssh"
suffix=$((10000 + RANDOM % 99999))
RG="mailman"
location="uksouth"
VM="mailman-ubuntu-${suffix}"
image="Ubuntu2204"

# Generating a random string to use as password
userName="postman"
#$randompass = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 30 | ForEach-Object {[char]$_})
#Read more: https://www.sharepointdiary.com/2020/04/powershell-generate-random-password.html#ixzz8XiwccFos
#$Password = ConvertTo-SecureString $randompass -AsPlainText -Force
#$psCred = New-Object System.Management.Automation.PSCredential($UserName, $Password)

echo "Creating virtual machine $VM in resource group $RG in location $location"
sleep 1
echo ""

echo "The Resource Group:"
# Create RG
az group create -n $RG -l $location
sleep 1
echo ""
echo "The virtual machine $VM:"

# Create Ubuntu VM
# New-AzVm -ResourceGroupName $RG -Name $vmName -Location $location -Image $image -VirtualNetworkName "myVnet-${suffix}" -SubnetName "vmsubnet" -SecurityGroupName "vmNSG" -PublicIpAddressName $publicIp -OpenPorts 80,22 -GenerateSshKey
az vm create -n $VM -g $RG --image $image --generate-ssh-keys --admin-username $userName --size Standard_D2s_v3 --nsg-rule ssh --public-ip-sku Standard

sleep 2
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
az vm run-command create --resource-group $RG --async-execution false --run-as-user $userName --script "sudo wget -O - https://raw.githubusercontent.com/karatheem/mailman/refs/heads/main/srv/spin-vm-guest.sh | bash" --timeout-in-seconds 3600 --run-command-name "SetDockerUp" --vm-name $VM

# Look for user input to perform ssh connection right now
read -p "Do you want to connect to ${VM} via ssh now? (y/n) " userinput
if [ "$userinput" = "y" ]; then
    az ssh vm -g "$RG" -n "$VM" --local-user "$userName" --yes
else
    echo "Save the command for later: az ssh vm -g $RG -n $VM --local-user $userName"
fi
