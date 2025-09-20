terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

resource "yandex_vpc_network" "this" {
  name = "${var.env}-vpc"
}

resource "yandex_vpc_subnet" "this" {
  name           = "${var.env}-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = var.cidr_blocks
}
