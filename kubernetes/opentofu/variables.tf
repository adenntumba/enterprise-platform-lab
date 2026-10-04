variable "proxmox_node" {
  description = "Proxmox node where Kubernetes VMs will be provisioned."
  type        = string
}

variable "kubernetes_template_id" {
  description = "Proxmox VMID of the Debian Cloud-Init template."
  type        = number
}

variable "kubernetes_vms" {
  description = "Kubernetes virtual machines to provision."
  type = map(object({
    role   = string
    cores  = number
    memory = number
    disk   = number
    mac    = string
  }))
}