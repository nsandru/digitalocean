output "External IP" {
  value = ["${digitalocean_droplet.dnsserver.*.ipv4_address}"]
}

output " External Name" {
  value = ["${digitalocean_record.ns.*.fqdn}"]
}

output "Internal IP" {
  value = ["${digitalocean_droplet.dnsserver.*.ipv4_address_private}"]
}

output " Internal Name" {
  value = ["${digitalocean_droplet.dnsserver.*.name}"]
}
