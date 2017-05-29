output "Public IP" {
  value = ["${digitalocean_droplet.gateway.*.ipv4_address}"]
}

output " Name" {
  value = ["${digitalocean_droplet.gateway.*.name}"]
}
