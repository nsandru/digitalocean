output "Public IP" {
  value = ["${digitalocean_droplet.dockerserver.*.ipv4_address}"]
}

output " Name" {
  value = ["${digitalocean_droplet.dockerserver.*.name}"]
}
