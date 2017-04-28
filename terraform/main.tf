# Provision docker servers based on CentOS 7
#
# The following environment variables have to be defined:
#
# Mandatory:
#   TF_VAR_sshkeys     = Comma separated list of SSH key records
#   TF_VAR_domain      = Domain
#   DIGITALOCEAN_TOKEN = Token for API access
#
# Optional:
#   TF_VAR_region      = Region (default nyc1)
#   TF_VAR_instances   = Number of droplets (default 1)

provider "digitalocean" {
}

resource "digitalocean_droplet" "dockerserver" {
  ssh_keys           = ["${var.sshkeys}"] # List of SSH keys for the droplets
  image              = "${var.centos}"    # Image to be used
  region             = "${var.region}"    # Region, default nyc1
  size               = "512mb"
  count              = "${var.instances}"
  private_networking = true
  backups            = true
  ipv6               = true
  name               = "dockerserver${count.index}.${var.region}.${var.domain}"

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sudo yum clean all",
      "sudo yum install -y epel-release",
      "sudo yum install -y ansible",
      "curl -fsSL https://get.docker.com/ | sh",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
    ]

    connection {
      type     = "ssh"
      private_key = "${file("~/.ssh/id_rsa")}"
      user     = "root"
      timeout  = "15m"
    }
  }
}

resource "digitalocean_record" "dockerserver" {
  domain = "${var.region}.${var.domain}"
  type = "A"
  name = "dockerserver${count.index}"
  value = "${element(digitalocean_droplet.dockerserver.*.ipv4_address, count.index)}"
  count = "${var.instances}"
}
