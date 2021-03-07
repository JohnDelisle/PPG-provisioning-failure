
provider "azurerm" {
  features {}
  subscription_id = "1e2b027a-24d8-48ba-80da-9412719e1201"
}


locals {
  tiers = {
    web = {
      name    = "web"
      vm_size = "Standard_B2MS"
      vm_suffixes = [
        "01",
        "02",
        "03",
        "04",
        "05",
        "06",
        "07",
        "08",
        "09",
        "10",
      ]
      data_disk_size = "64"
      data_disk_suffixes = [
        "01",
        "02",
      ]
    }
    app = {
      name    = "app"
      vm_size = "Standard_DS3_v2"
      vm_suffixes = [
        "01",
        "02",
        "03",
        "04",
        "05",
        "06",
        "07",
        "08",
        "09",
        "10",
      ]
      data_disk_size = "64"
      data_disk_suffixes = [
        "01",
        "02",
      ]
    }
    data = {
      name    = "data"
      vm_size = "Standard_D8ds_v4"
      vm_suffixes = [
        "01",
        "02",
        "03",
        "04",
        "05",
        "06",
        "07",
        "08",
        "09",
        "10",
        "11",
        "12",
        "13",
        "14",
        "15",
        "16",
        "17",
        "18",
        "19",
        "20",
      ]
      data_disk_size = "64"
      data_disk_suffixes = [
        "01",
        "02",
        "03",
        "04",
        "05",
        "06",
      ]
    }
  }
}

// RG
resource "azurerm_resource_group" "pod" {
  name     = "jmd-test-new"
  location = "EastUS2"
}

// VNet
resource "azurerm_virtual_network" "pod_vnet" {
  name                = "${azurerm_resource_group.pod.name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.pod.location
  resource_group_name = azurerm_resource_group.pod.name
}

// Subnet
resource "azurerm_subnet" "pod_subnet" {
  name                 = "${azurerm_resource_group.pod.name}-subnet"
  resource_group_name  = azurerm_resource_group.pod.name
  virtual_network_name = azurerm_virtual_network.pod_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

// PPG
resource "azurerm_proximity_placement_group" "pod_ppg" {
  name                = "${azurerm_resource_group.pod.name}-ppg"
  location            = azurerm_resource_group.pod.location
  resource_group_name = azurerm_resource_group.pod.name
}

// Create the pod tiers, web, app, data
module "pod_tier" {
  source   = "./pod_tier"
  for_each = local.tiers

  rg     = azurerm_resource_group.pod
  ppg    = azurerm_proximity_placement_group.pod_ppg
  tier   = each.value
  subnet = azurerm_subnet.pod_subnet
}


