terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

resource "yandex_compute_instance" "k3s" {
  for_each = { for node in var.nodes : node.name => node }

  name        = each.value.name
  platform_id = each.value.platform
  zone        = var.yc_zone

  allow_stopping_for_update = true

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = each.value.fraction
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      size     = each.value.disk
      image_id = var.image_id
    }
  }

  network_interface {
    subnet_id  = var.subnet_id
    nat             = each.value.name == var.master_name
    nat_ip_address  = each.value.name == var.master_name ? yandex_vpc_address.master_ip.external_ipv4_address[0].address : null
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_key_path)}"
    user-data = <<-EOF
      #cloud-config
      hostname: ${each.value.name}
      datasource_list: [ConfigDrive, Ec2, None]
    EOF
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_ed25519_yacloud")
    host        = self.network_interface[0].nat_ip_address
  }

  provisioner "file" {
    source      = "~/.ssh/id_ed25519_yacloud"
    destination = "/home/ubuntu/.ssh/id_ed25519_yacloud"
    on_failure  = continue
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/ubuntu/.ssh/id_ed25519_yacloud",
      "chown ubuntu:ubuntu /home/ubuntu/.ssh/id_ed25519_yacloud"
    ]
    on_failure = continue
  }
}

resource "yandex_vpc_address" "master_ip" {
  name = "${var.env}-master-ip"
  external_ipv4_address {
    zone_id = var.yc_zone
  }
}
