output "kubernetes_vm_ids" {
  description = "VM IDs of the Kubernetes nodes."
  value = {
    for name, vm in proxmox_virtual_environment_vm.kubernetes :
    name => vm.vm_id
  }
}

output "kubernetes_vm_names" {
  description = "Names of the Kubernetes nodes."
  value = [
    for name, vm in proxmox_virtual_environment_vm.kubernetes :
    vm.name
  ]
}

output "kubernetes_vm_mac_addresses" {
  description = "MAC addresses of the Kubernetes nodes."
  value = {
    for name, vm in proxmox_virtual_environment_vm.kubernetes :
    name => vm.mac_addresses
  }
}

# output "kubernetes_vm_ipv4_addresses" {
#   description = "IPv4 addresses of the Kubernetes nodes."
#   value = {
#     for name, vm in proxmox_virtual_environment_vm.kubernetes :
#     name => vm.ipv4_addresses
#   }
# }