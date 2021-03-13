targetScope = 'subscription'

var rg_name = 'YOUR RG NAME'
var location = 'YOUR REGION'

// this defines what we call a 'pod', an N-tier applicaiton with web, app, and SQL tiers.
// you may want to adjust the quanitity and size of VMs, or the number of data disks
// this is just an example to trigger the PPG/ mixed VM series issues, and doesn't actually provision licensed SQL VMs
var tiers = [
  {
    name: 'web'
    vm_size: 'Standard_B2MS'
    // VMs will be created for each suffix below
    vm_suffixes: [
      '01'
      '02'
      '03'
      '04'
      '05'
      '06'
      '07'
      '08'
      '09'
      '10'
    ]
    data_disk_size: 64
    // Data disks will be created per-VM for each suffix below
    data_disk_suffixes: [
      '01'
      '02'
    ]
  }
  {
    name: 'app'
    vm_size: 'Standard_DS3_v2'
    vm_suffixes: [
      '01'
      '02'
      '03'
      '04'
      '05'
      '06'
      '07'
      '08'
      '09'
      '10'
    ]
    data_disk_size: 64
    data_disk_suffixes: [
      '01'
      '02'
    ]
  }
  {
    name: 'data'
    vm_size: 'Standard_D8ds_v4'
    vm_suffixes: [
      '01'
      '02'
      '03'
      '04'
      '05'
      '06'
      '07'
      '08'
      '09'
      '10'
      '11'
      '12'
      '13'
      '14'
      '15'
      '16'
      '17'
      '18'
      '19'
      '20'
    ]
    data_disk_size: 64
    data_disk_suffixes: [
      '01'
      '02'
      '03'
      '04'
      '05'
      '06'
    ]
  }
]

// RG
resource pod_rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: rg_name
  location: location
}

module pod './pod_infra.bicep' = {
  name: 'pod_infra'
  scope: pod_rg
  params: {
    tiers: tiers
  }
}