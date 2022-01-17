# SMS Homework - Azure VM deployment


# Set deployment variables
$location = "westeurope"

# Networking variables
$subnetName = "testSubnet"
$virtualNetworkName = "testVNET"
$networkInterfaceName = "testNic"
$publicIPname = "testPIP-1"
$nsgName = "testNetworkSecurityGroup"

# VM variables
$vmName = "testVM1"
$vmSize = "Standard_B1s"
$vmUserName = "azureuser"

# Storage variables
$storageAccountName = "shstorageaccount01"
$skuName = "Standard_LRS" # Standard Locally Redundant Storage

# Create variable for VM password - empty ve wil be using RSA key
$VMPassword = ' '

# Prompt for deployment name
$deploymentName = Read-Host -Prompt 'Input your deployment name'
$resourceGroupName = "shs-homework-"+$deploymentName

# Create a resource group
New-AzResourceGroup -Name $resourceGroupName -Location $location


# Create storage resources if storage account is available
#https://stackoverflow.com/questions/63664876/unable-to-create-storage-account-from-portal-name-already-taken
if (Get-AzStorageAccountNameAvailability -Name $storageAccountName) {

  $storageAccount = New-AzStorageAccount `
    -Location $location `
    -ResourceGroupName $resourceGroupName `
    -Type $skuName `
    -Name $storageAccountName
}


# Create a subnet configuration
$subnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name $subnetName `
  -AddressPrefix "192.168.1.0/24"

# Create a virtual network
$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $resourceGroupName `
  -Location $location `
  -Name $virtualNetworkName `
  -AddressPrefix "192.168.0.0/16" `
  -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$pip = New-AzPublicIpAddress `
  -Name $publicIPname `
  -ResourceGroupName $resourceGroupName `
  -Location $location `
  -AllocationMethod Static `
  -IdleTimeoutInMinutes 4


#following is unwanted in this assignment
# Create an inbound network security group rule for port 22
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
  -Name "testNetworkSecurityGroupRuleSSH" `
  -Protocol "Tcp" `
  -Direction "Inbound" `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 22 `
  -Access "Deny"

# # Create a network security group
$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName $resourceGroupName `
  -Location $location `
  -Name $nsgName `
  -SecurityRules $nsgRuleSSH


# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface `
  -Name $networkInterfaceName `
  -ResourceGroupName $resourceGroupName `
  -Location $location `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $pip.Id `
  -NetworkSecurityGroupId $nsg.Id

# Define a credential object
$securePassword = ConvertTo-SecureString $VMPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($vmUserName, $securePassword)

# Create a virtual machine configuration
$vmConfig = New-AzVMConfig `
  -VMName $vmName `
  -VMSize $vmSize | `
Set-AzVMOperatingSystem `
  -Linux `
  -ComputerName $vmName `
  -Credential $cred `
  -DisablePasswordAuthentication | `
Set-AzVMSourceImage `
  -PublisherName "Canonical" `
  -Offer "UbuntuServer" `
  -Skus "18.04-LTS" `
  -Version "latest" | `
Add-AzVMNetworkInterface `
  -Id $nic.Id

# Configure the SSH key
$sshPublicKey = cat ~/.ssh/id_rsa.pub
Add-AzVMSshPublicKey `
  -VM $vmconfig `
  -KeyData $sshPublicKey `
  -Path "/home/$vmUserName/.ssh/authorized_keys"


New-AzVM `
  -ResourceGroupName $resourceGroupName `
  -Location $location `
  -VM $vmConfig


Get-AzPublicIpAddress -ResourceGroupName $resourceGroupName | Select "IpAddress"


Invoke-AzVMRunCommand `
  -ResourceGroupName $resourceGroupName `
  -VMName $vmName `
  -CommandId 'RunShellScript' `
  -ScriptPath './update.sh' `
  -Parameter @{"upgrades" = "true"} `
  -Debug `
  -Confirm:$false


# Watch Out! Following is DESTRUCTIVE and too slow ;)
#Remove-AzResourceGroup -Name $resourceGroupName
