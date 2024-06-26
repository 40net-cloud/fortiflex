##############################################################################################################
#
# FortiGate a standalone FortiGate VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
#
# Output summary of deployment
#
##############################################################################################################

output "deployment_summary" {
  value = templatefile("${path.module}/summary.tpl", {
    username                   = var.USERNAME
    location                   = var.LOCATION
    fgt_ipaddress              = data.azurerm_public_ip.fgtpip.ip_address
    fgt_private_ip_address_ext = azurerm_network_interface.fgtifcext.private_ip_address
    fgt_private_ip_address_int = azurerm_network_interface.fgtifcint.private_ip_address
    fgt_fortiflex_serial       = fortiflexvm_entitlements_vm.fortiflex_vm.serial_number
#    fgt_fortiflex_serial       = fortiflexvm_entitlements_vm_token.fortiflex_vm.serial_number
  })
}
