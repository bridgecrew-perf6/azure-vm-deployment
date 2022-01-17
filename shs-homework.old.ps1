# Prompt for deployment name
$deploymentName = Read-Host -Prompt 'Input your deployment name'
$resourceGropName = "shs-homework-"+$deploymentName
$location = "westeurope"
$subnetName = "testSubnet"
$virtualNetworkName = "testVNET"
$networkInterfaceName = "testNic"
$publicIPname = "testPIP"
$securityGroupName = "testNetworkSecurityGroup"
$vmName = "testVM1"
$vmSize = "Standard_B1s"
$vmUserName = "azureuser"

# Create a resource group
New-AzResourceGroup -Name $resourceGropName -Location $location

# Create a subnet configuration
$subnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name $subnetName `
  -AddressPrefix "192.168.1.0/24"

# Create a virtual network
$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $resourceGropName `
  -Location $location `
  -Name $virtualNetworkName `
  -AddressPrefix "192.168.0.0/16" `
  -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$pip = New-AzPublicIpAddress `
  -Name $publicIPname `
  -ResourceGroupName $resourceGropName `
  -Location $location `
  -AllocationMethod Static `
  -IdleTimeoutInMinutes 4


# following is unwanted in this assignment
# Create an inbound network security group rule for port 22
# $nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
#   -Name "testNetworkSecurityGroupRuleSSH" `
#   -Protocol "Tcp" `
#   -Direction "Inbound" `
#   -Priority 1000 `
#   -SourceAddressPrefix * `
#   -SourcePortRange * `
#   -DestinationAddressPrefix * `
#   -DestinationPortRange 22 `
#   -Access "Allow"


# Create a network security group
$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName $resourceGropName `
  -Location $location `
  -Name $securityGroupName `
  -SecurityRules $nsgRuleSSH

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface `
  -Name $networkInterfaceName `
  -ResourceGroupName $resourceGropName `
  -Location $location `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $pip.Id `
  -NetworkSecurityGroupId $nsg.Id

# Define a credential object
$securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
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
  -ResourceGroupName $resourceGropName `
  -Location westeurope `
  -VM $vmConfig


Get-AzPublicIpAddress -ResourceGroupName $resourceGropName | Select "IpAddress"


Invoke-AzVMRunCommand `
  -ResourceGroupName $resourceGropName `
  -VMName $vmName `
  -CommandId 'RunShellScript' `
  -ScriptPath './update.sh' `
  -Debug `
  -Confirm:$false
  #-Parameter @{"arg1" = "var1";"arg2" = "var2"}


# Watch Out! Following is DESTRUCTIVE and too slow ;)
#Remove-AzResourceGroup -Name $resourceGropName

