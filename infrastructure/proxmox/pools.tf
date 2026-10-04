resource "proxmox_virtual_environment_pool" "vm_pool" {
  for_each = var.vm_pools

  comment = "Managed by OpenTofu"
  pool_id = each.value.pool_id
}