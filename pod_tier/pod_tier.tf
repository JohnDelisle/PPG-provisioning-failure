variable "rg" {}
variable "ppg" {}
variable "tier" {}
variable "subnet" {}

// AV
resource "azurerm_availability_set" "av" {
  name                         = "${var.rg.name}-${var.tier.name}-av"
  location                     = var.rg.location
  resource_group_name          = var.rg.name
  proximity_placement_group_id = var.ppg.id
}

// Create one VM for each VM suffix
module "pod_vm" {
  source   = "./pod_vm"
  for_each = toset(var.tier.vm_suffixes)

  rg     = var.rg
  av     = azurerm_availability_set.av
  ppg    = var.ppg
  subnet = var.subnet

  vm_name = "${var.tier.name}-vm${each.value}"
  vm_size = var.tier.vm_size

  data_disk_suffixes = var.tier.data_disk_suffixes
  data_disk_size     = var.tier.data_disk_size
}
