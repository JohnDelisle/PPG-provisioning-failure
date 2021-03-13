param tiers array

// VNet and Subnet
resource pod_vnet 'Microsoft.Network/virtualnetworks@2015-05-01-preview' = {
  name: '${resourceGroup().name}-vnet'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${resourceGroup().name}-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

resource pod_ppg 'Microsoft.Compute/proximityPlacementGroups@2020-06-01' = {
  name: '${resourceGroup().name}-ppg'
  location: resourceGroup().location
  properties: {
    proximityPlacementGroupType: 'Standard'
  }
}

module pod_tier './pod_infra_tier.bicep' = [for tier in tiers: {
  name: 'pod_infra_tier_${tier.name}'
  scope: resourceGroup()
  params: {
    tier: tier
    vnet_id: pod_vnet.id
    ppg_id: pod_ppg.id
  }
}]