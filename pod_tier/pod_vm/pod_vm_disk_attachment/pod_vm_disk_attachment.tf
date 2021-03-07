
variable "disk" {}
variable "vm" {}
variable "lun" {}

resource "azurerm_virtual_machine_data_disk_attachment" "lun" {
  managed_disk_id    = var.disk.id
  virtual_machine_id = var.vm.id
  lun                = var.lun
  caching            = "ReadWrite"
}
