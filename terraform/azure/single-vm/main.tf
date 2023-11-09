##############################################################################################################
#
# FortiGate a standalone FortiGate VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
#
# Deployment of the virtual network
#
##############################################################################################################

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.PREFIX}-vnet"
  address_space       = [var.vnet]
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_subnet" "subnet1" {
  name                 = "${var.PREFIX}-subnet-fgt-external"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet["1"]]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "${var.PREFIX}-subnet-fgt-internal"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet["2"]]
}

resource "azurerm_subnet" "subnet3" {
  name                 = "${var.PREFIX}-subnet-protected-a"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet["3"]]
}

resource "azurerm_subnet_route_table_association" "subnet3rt" {
  subnet_id      = azurerm_subnet.subnet3.id
  route_table_id = azurerm_route_table.protectedaroute.id

  lifecycle {
    ignore_changes = [route_table_id]
  }
}

resource "azurerm_route_table" "protectedaroute" {
  name                = "${var.PREFIX}-rt-protected-a"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name

  route {
    name                   = "VirtualNetwork"
    address_prefix         = var.vnet
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fgt_ipaddress["2"]
  }
  route {
    name           = "Subnet"
    address_prefix = var.subnet["3"]
    next_hop_type  = "VnetLocal"
  }
  route {
    name                   = "Default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fgt_ipaddress["2"]
  }
}

resource "azurerm_network_security_group" "fgtnsg" {
  name                = "${var.PREFIX}-fgt-nsg"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_network_security_rule" "fgtnsgallowallout" {
  name                        = "AllowAllOutbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fgtnsg.name
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fgtnsgallowallin" {
  name                        = "AllowAllInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fgtnsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_public_ip" "fgtpip" {
  name                = "${var.PREFIX}-fgt-pip"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "lb-pip")
}

resource "azurerm_network_interface" "fgtifcext" {
  name                          = "${var.PREFIX}-fgt-nic1-ext"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.FGT_ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress["1"]
    public_ip_address_id          = azurerm_public_ip.fgtpip.id
  }
}

resource "azurerm_network_interface_security_group_association" "fgtifcextnsg" {
  network_interface_id      = azurerm_network_interface.fgtifcext.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_network_interface" "fgtifcint" {
  name                 = "${var.PREFIX}-fgt-nic2-int"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress["2"]
  }
}

resource "azurerm_network_interface_security_group_association" "fgtifcintnsg" {
  network_interface_id      = azurerm_network_interface.fgtifcint.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_linux_virtual_machine" "fgtvm" {
  name                         = "${var.PREFIX}-fgt-vm"
  location                     = azurerm_resource_group.resourcegroup.location
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  network_interface_ids        = [azurerm_network_interface.fgtifcext.id, azurerm_network_interface.fgtifcint.id]
  size                         = var.fgt_vmsize

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm_v5"
    sku       = var.FGT_IMAGE_SKU
    version   = var.FGT_VERSION
  }

  plan {
    publisher = "fortinet"
    product   = "fortinet_fortigate-vm_v5"
    name      = var.FGT_IMAGE_SKU
  }

  os_disk {
    name                 = "${var.PREFIX}-fgt-a-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = var.USERNAME
  admin_password                  = var.PASSWORD
  disable_password_authentication = false
  custom_data = base64encode(templatefile("${path.module}/customdata.tftpl", {
    fgt_vm_name         = "${var.PREFIX}-fgt"
    fgt_license_file    = var.FGT_BYOL_LICENSE_FILE
#    fgt_license_flexvm  = fortiflexvm_entitlements_vm.fortiflex_vm.token
    fgt_license_flexvm  = fortiflexvm_entitlements_vm_token.fortiflex_vm.token
    fgt_username        = var.USERNAME
    fgt_ssh_public_key  = var.FGT_SSH_PUBLIC_KEY_FILE
    fgt_external_ipaddr = var.fgt_ipaddress["1"]
    fgt_external_mask   = var.subnetmask["1"]
    fgt_external_gw     = var.gateway_ipaddress["1"]
    fgt_internal_ipaddr = var.fgt_ipaddress["2"]
    fgt_internal_mask   = var.subnetmask["2"]
    fgt_internal_gw     = var.gateway_ipaddress["2"]
    fgt_protected_net   = var.subnet["3"]
    vnet_network        = var.vnet
  }))

  boot_diagnostics {
  }

  lifecycle {
    ignore_changes = [custom_data]
  }

  tags = var.fortinet_tags
}

resource "azurerm_managed_disk" "fgtvm-datadisk" {
  name                 = "${var.PREFIX}-fgt-vm-datadisk"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 50
}

resource "azurerm_virtual_machine_data_disk_attachment" "fgtvm-datadisk-attach" {
  managed_disk_id    = azurerm_managed_disk.fgtvm-datadisk.id
  virtual_machine_id = azurerm_linux_virtual_machine.fgtvm.id
  lun                = 0
  caching            = "ReadWrite"
}

data "azurerm_public_ip" "fgtpip" {
  name                = azurerm_public_ip.fgtpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
  depends_on          = [azurerm_linux_virtual_machine.fgtvm]
}

output "fgt_public_ip_address" {
  value = data.azurerm_public_ip.fgtpip.ip_address
}

#resource "fortiflexvm_entitlements_vm" "fortiflex_vm"{
#  config_id = var.FORTIFLEX_CONFIG_ID
#  description = "Terraform managed" # Optional.
#  folder_path = "My Assets/2023"
#  # status = "ACTIVE" # "ACTIVE" or "STOPPED". Optional. It has many restrictions. Not recommended to set it manually.
#}
#output "debug_fortiflex"{
#    value = fortiflexvm_entitlements_vm.fortiflex_vm
#}
#output "debug_fortiflex_token"{
#    value = fortiflexvm_entitlements_vm.fortiflex_vm.token
#}

resource "fortiflexvm_entitlements_vm_token" "fortiflex_vm"{
  config_id = var.FORTIFLEX_CONFIG_ID
  serial_number = var.FORTIFLEX_SERIALNUMBER
  regenerate_token = true # If set as false, the provider would only provide the token and not regenerate the token.
}
output "debug_fortiflex"{
#    value = fortiflexvm_entitlements_vm.fortiflex_vm
    value = fortiflexvm_entitlements_vm_token.fortiflex_vm
}
output "debug_fortiflex_token"{
#    value = fortiflexvm_entitlements_vm.fortiflex_vm.token
    value = fortiflexvm_entitlements_vm_token.fortiflex_vm.token
}
