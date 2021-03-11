[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][String]$subscription_id,
    [Parameter(Mandatory = $true)][String]$rg_name,
    [Parameter(Mandatory = $true)][String]$location
)

$ErrorActionPreference = "Inquire"

# Note that because this script use -AsJob on New-AzVm, the script may appear to run successfully.
# However, upon script completion, check the Azure portal and you will see the VMs have failed to provision due to capacity errors.
# Also visible via Get-Job to observe the failed backgrounded jobs.


$vmAdminUsername = "adminuser"
$vmAdminPassword = ConvertTo-SecureString 'P@$$w0rd1234!' -AsPlainText -Force
$vmCredential = New-Object System.Management.Automation.PSCredential ($vmAdminUsername, $vmAdminPassword)

$tiers = @(
    @{
        name               = "web"
        vm_size            = "Standard_B2MS"
        quantity           = 10
        data_disk_size     = 64
        data_disk_quantity = 2
    }, 
    @{
        name               = "app"
        vm_size            = "Standard_DS3_v2"
        quantity           = 10
        data_disk_size     = 64
        data_disk_quantity = 2
    },
    @{
        name               = "data"
        vm_size            = "Standard_D8ds_v4"
        quantity           = 20
        data_disk_size     = 64
        data_disk_quantity = 6
    }
)


Login-AzAccount
Set-AzContext -SubscriptionId $subscription_id

# RG
Write-Output "Creating Resource Group $rg_name"
$rg = New-AzResourceGroup `
    -Name $rg_name `
    -Location $location

# Subnet
Write-Output "Creating Subnet config"
$subnet = New-AzVirtualNetworkSubnetConfig `
    -Name "$($rg.ResourceGroupName)-subnet" `
    -AddressPrefix "10.0.2.0/24"

# VNet
Write-Output "Creating VNet"
$vnet = New-AzVirtualNetwork `
    -Name "$($rg.ResourceGroupName)-vnet" `
    -ResourceGroupName $rg.ResourceGroupName `
    -Location $rg.Location `
    -AddressPrefix "10.0.0.0/16" `
    -Subnet $subnet

# Get the subnet
$subnet = Get-AzVirtualNetworkSubnetConfig `
    -Name "$($rg.ResourceGroupName)-subnet" `
    -VirtualNetwork $vnet

# PPG
$ppg = New-AzProximityPlacementGroup `
    -Name "$($rg.ResourceGroupName)-ppg" `
    -ResourceGroupName $rg.ResourceGroupName `
    -Location $rg.Location `
    -ProximityPlacementGroupType Standard

foreach ($tier in $tiers) {
    Write-Output "Provisioning $($tier.name)"


    # AV
    Write-Output "Creating AV"
    $av = New-AzAvailabilitySet `
        -Name "$($rg.ResourceGroupName)-$($tier.name)-av" `
        -ResourceGroupName $rg.ResourceGroupName `
        -Location $rg.location `
        -ProximityPlacementGroupId $ppg.Id `
        -Sku "Aligned" `
        -platformFaultDomainCount 2

    # Create all the VMs
    for ($vmIndex = 1; $vmIndex -le $tier.quantity; $vmIndex++) {
        $vmSuffix = "{0:d2}" -f $vmIndex
        $vmName = "$($tier.name)-vm$vmSuffix"

        # NIC
        Write-Output "Creating NIC"
        $nic = New-AzNetworkInterface `
            -Name "$vmName-nic" `
            -ResourceGroupName $rg.ResourceGroupName `
            -Location $rg.Location `
            -SubnetId $subnet.Id 

        # new VM config
        Write-Output "Creating VM Config for $vmName"        
        $vm = New-AzVMConfig `
            -VMName $vmName `
            -VMSize $tier.vm_size `
            -AvailabilitySetId $av.Id `
            -ProximityPlacementGroupId $ppg.ID `
            
        # set OS profile
        Write-Output "Setting OS profile"
        $vm = Set-AzVMOperatingSystem `
            -VM $vm `
            -Windows `
            -ComputerName $vmName `
            -Credential $vmCredential 

        # Add NIC
        Write-Output "Adding NIC"
        $vm = Add-AzVMNetworkInterface `
            -VM $vm `
            -Id $nic.Id

        # Set OS source image
        Write-Output "Setting source image"
        $vm = Set-AzVMSourceImage `
            -VM $vm `
            -PublisherName "MicrosoftWindowsServer" `
            -Offer "WindowsServer" `
            -Skus "2019-Datacenter-Core-smalldisk" `
            -Version "latest"
        
        # disable diag
        Write-Output "Setting diags"
        $vm = Set-AzVMBootDiagnostic `
            -VM $vm `
            -Disable
        
        # config OS disk
        Write-Output "Setting OS Disk"
        $vm = Set-AzVMOSDisk `
            -Name "$vmName-os" `
            -VM $vm `
            -StorageAccountType "Premium_LRS" `
            -Caching ReadWrite `
            -CreateOption FromImage 

        # add the data disks
        for ($dataDiskIndex = 1; $dataDiskIndex -le $tier.data_disk_quantity; $dataDiskIndex++) {
            $diskSuffix = "{0:d2}" -f $dataDiskIndex
            $dataDiskName = "$vmName-data$diskSuffix" 

            # data disk config
            Write-Output "Creating disk config"
            $diskConfig = New-AzDiskConfig `
                -SkuName Premium_LRS `
                -Location $location `
                -CreateOption Empty `
                -DiskSizeGB $tier.data_disk_size

            # create the data disk
            Write-Output "Creating data disk $diskName"
            $dataDisk = New-AzDisk `
                -DiskName $dataDiskName `
                -Disk $diskConfig `
                -ResourceGroupName $rg.ResourceGroupName

            # attach to VM
            Write-Output "Attaching $($dataDisk.Name) to $vmName"
            $vm = Add-AzVMDataDisk `
                -VM $vm `
                -Name $dataDisk.Name `
                -CreateOption Attach `
                -ManagedDiskId $dataDisk.Id `
                -Lun (10 + $dataDiskIndex)
        }
        
        # create VM
        Write-Output "Creating VM $vmName"
        New-AzVm `
            -VM $vm `
            -ResourceGroupName $rg.ResourceGroupName `
            -Location $rg.Location `
            -asjob
    
    }
}


