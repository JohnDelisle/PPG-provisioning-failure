variable "rg" {}
variable "data_disk_name" {}
variable "data_disk_size" {}

// VM Data Disks
resource "azurerm_managed_disk" "disk" {
  name                 = var.data_disk_name
  location             = var.rg.location
  resource_group_name  = var.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size
}

output "disk" {
  value = azurerm_managed_disk.disk
}
