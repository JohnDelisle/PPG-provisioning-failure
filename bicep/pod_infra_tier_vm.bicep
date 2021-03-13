param vnet_id string
param subnet_name string

param av_id string
param ppg_id string

param vm_name string
param vm_size string
param vm_suffix string

param data_disk_suffixes array
param data_disk_size int

// This will be your Secondary NIC
resource nic 'Microsoft.Network/networkInterfaces@2017-06-01' = {
  name: '${vm_name}-nic'
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnet_id}/subnets/${subnet_name}'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vm_name
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vm_size
    }
    osProfile: {
      computerName: vm_name
      adminUsername: 'adminuser'
      adminPassword: 'P@$$w0rd1234!'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter-Core-smalldisk'
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [for data_disk_suffix in data_disk_suffixes: {
        diskSizeGB: data_disk_size
        lun: (10 + int(data_disk_suffix))
        createOption: 'Empty'
      }]
    }
    proximityPlacementGroup: {
      id: ppg_id
    }
    availabilitySet: {
      id: av_id
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}