resource "proxmox_virtual_environment_vm" "kubernetes" {
  for_each = var.kubernetes_vms

  name      = each.key
  node_name = var.proxmox_node
  pool_id   = data.proxmox_virtual_environment_pool.kubernetes.pool_id

  clone {
    vm_id = var.kubernetes_template_id
    # retries = 3
  }

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = "vmdata"
    interface    = "scsi0"
    size         = each.value.disk
  }

  initialization {
    datastore_id = "vmdata"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = "debian"
      keys = [
        trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))
      ]
    }
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = each.value.mac
  }

  agent {
    enabled = false
  }

  operating_system {
    type = "l26"
  }

  started = true
}