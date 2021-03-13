param tier object
param vnet_id string
param ppg_id string

resource av 'Microsoft.Compute/availabilitySets@2020-06-01' = {
  name: '${resourceGroup().name}-av'
  location: resourceGroup().location
  properties: {
    proximityPlacementGroup: {
      id: ppg_id
    }
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

module pod_vm './pod_infra_tier_vm.bicep' = [for vm_suffix in tier.vm_suffixes: {
  name: 'pod_infra_tier_${tier.name}_vm_${vm_suffix}'
  scope: resourceGroup()
  params: {
    vm_suffix: vm_suffix
    av_id: av.id
    ppg_id: ppg_id
    vnet_id: vnet_id
    subnet_name: '${resourceGroup().name}-subnet'

    vm_name: '${tier.name}-vm${vm_suffix}'
    vm_size: tier.vm_size

    data_disk_suffixes: tier.data_disk_suffixes
    data_disk_size: tier.data_disk_size
  }
}]