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
#   TF_VAR_region       = Region (default nyc1)
#                         The droplets are created in Region.Domain
#   TF_VAR_instances    = Number of droplets (default 1)
#   TF_VAR_createdomain = Set to 1 if the domain has to be created
#
# Nick Sandru 20170430

provider "digitalocean" {}

resource "digitalocean_droplet" "dockerserver" {
  ssh_keys           = ["${var.sshkeys}"]                                       # List of SSH keys for the droplets
  image              = "${var.centos}"                                          # Image to be used
  region             = "${var.region}"                                          # Region, default nyc1
  size               = "512mb"
  count              = "${var.instances}"
  private_networking = true
  backups            = true
  ipv6               = true
  name               = "dockerserver${count.index}.${var.region}.${var.domain}"

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "yum clean all",
      "yum install -y epel-release",
      "yum install -y ansible unzip",
      "curl -fsSL https://get.docker.com/ | sh",
      "systemctl start docker",
      "systemctl enable docker",
    ]
  }

  provisioner "local-exec" {
    command = "tar zcf files/digitalocean.tar.gz files/json ansible"
  }

  provisioner "file" {
    source      = "files/digitalocean.tar.gz"
    destination = "/tmp/digitalocean.tar.gz"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /root",
      "tar zxf /tmp/digitalocean.tar.gz",
      "wget https://releases.hashicorp.com/packer/1.0.0/packer_1.0.0_linux_amd64.zip -O files/packer.zip",
      "wget https://releases.hashicorp.com/consul/0.8.1/consul_0.8.1_linux_amd64.zip -O files/consul.zip",
      "cd /usr/local/bin",
      "unzip /root/files/packer.zip",
      "unzip /root/files/consul.zip",
      "chmod +x packer consul",
      "packer build /root/files/json/centos.json",
      "packer build /root/files/json/nginx.json",
    ]
  }

  connection {
    type        = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    user        = "root"
    timeout     = "15m"
  }
}

resource "digitalocean_domain" "dockerserver" {
  count  = "${var.createdomain}"
  name   = "${var.region}.${var.domain}"
  ip_address = "${digitalocean_droplet.dockerserver.0.ipv4_address}"
}

resource "digitalocean_record" "dockerserver" {
  domain = "${var.region}.${var.domain}"
  type   = "A"
  name   = "dockerserver${count.index}"
  value  = "${element(digitalocean_droplet.dockerserver.*.ipv4_address, count.index)}"
  count  = "${var.instances}"
}
