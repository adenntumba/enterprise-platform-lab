variable "vm_pools" {
  description = "Proxmox VM pools managed by OpenTofu."
  type = map(object({
    pool_id = string
  }))
}