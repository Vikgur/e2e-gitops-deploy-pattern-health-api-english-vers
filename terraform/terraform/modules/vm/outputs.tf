output "k3s_external_ips" {
  value = {
    for name, inst in yandex_compute_instance.k3s :
    name => inst.network_interface[0].nat_ip_address
  }
}

output "k3s_master_ip" {
  value = yandex_vpc_address.master_ip.external_ipv4_address[0].address
}
