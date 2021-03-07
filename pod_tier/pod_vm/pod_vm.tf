variable "rg" {}
variable "av" {}
variable "ppg" {}
variable "subnet" {}
variable "vm_name" {}
variable "vm_size" {}
variable "data_disk_suffixes" {}
variable "data_disk_size" {}


// VM NIC
resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.rg.location
  resource_group_name = var.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

// VM Disks - create one disk for each data_disk_suffixes
module "pod_vm_disk" {
  source   = "./pod_vm_disk"
  for_each = toset(var.data_disk_suffixes)

  rg             = var.rg
  data_disk_name = "${var.vm_name}-data${each.value}"
  data_disk_size = var.data_disk_size
}


// VM
resource "azurerm_windows_virtual_machine" "vm" {
  name          = var.vm_name
  computer_name = replace(var.vm_name, "-", "")

  resource_group_name = var.rg.name
  location            = var.rg.location

  availability_set_id          = var.av.id
  proximity_placement_group_id = var.ppg.id
  size                         = var.vm_size

  admin_username = "adminuser"
  admin_password = "P@$$w0rd1234!"

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter-Core-smalldisk"
    version   = "latest"
  }
}

// VM Disks Attachment - attach one disk for each data_disk_suffixes
module "pod_vm_disk_attachment" {
  source   = "./pod_vm_disk_attachment"
  for_each = toset(var.data_disk_suffixes)

  disk = module.pod_vm_disk[each.value].disk
  vm   = azurerm_windows_virtual_machine.vm
  lun  = 10 + tonumber(each.value)
}
