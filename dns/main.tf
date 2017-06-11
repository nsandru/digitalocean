# Provision dnsserver systems based on CentOS 7
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
# Nick Sandru 20170609

provider "digitalocean" {}

resource "digitalocean_droplet" "dnsserver" {
  ssh_keys           = ["${var.sshkeys}"]                                       # List of SSH keys for the droplets
  image              = "${var.centos}"                                          # Image to be used
  region             = "${var.region}"                                          # Region, default nyc1
  size               = "512mb"
  count              = "${var.instances}"
  private_networking = true
  backups            = true
  ipv6               = true
  name               = "dnsserver${count.index}.${var.region}.${var.domain}"

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "yum clean all",
      "yum install -y unzip bind-chroot bind-utils",
    ]
  }

  provisioner "local-exec" {
    command = "tar zcf digitalocean.tar.gz files"
  }

  provisioner "file" {
    source      = "digitalocean.tar.gz"
    destination = "/tmp/digitalocean.tar.gz"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /root",
      "tar zxf /tmp/digitalocean.tar.gz",
      "wget https://releases.hashicorp.com/consul/0.8.1/consul_0.8.1_linux_amd64.zip -O files/consul.zip",
      "cd /usr/local/bin",
      "unzip /root/files/consul.zip",
      "chmod +x consul",
      "systemctl enable named-chroot",
      "cp -p /etc/named.* /var/named/chroot/etc",
      "mkdir -m 0750 -p /var/named/chroot/var/named/data /var/named/chroot/var/named/dynamic",
      "chown named.named /var/named/chroot/var/named/data /var/named/chroot/var/named/dynamic",
      "cp -p /var/named/named.* /var/named/chroot/var/named",
    ]
  }

  connection {
    type        = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    user        = "root"
    timeout     = "15m"
  }
}

resource "digitalocean_domain" "dnsserver" {
  count  = "${var.createdomain}"
  name   = "${var.region}.${var.domain}"
  ip_address = "${digitalocean_droplet.dnsserver.0.ipv4_address}"
}

resource "digitalocean_record" "ns" {
  domain = "${var.region}.${var.domain}"
  type   = "A"
  name   = "ns${count.index}"
  value  = "${element(digitalocean_droplet.dnsserver.*.ipv4_address, count.index)}"
  count  = "${var.instances}"
}

resource "digitalocean_record" "dnsserver" {
  domain = "${var.region}.${var.domain}"
  type   = "A"
  name   = "dnsserver${count.index}"
  value  = "${element(digitalocean_droplet.dnsserver.*.ipv4_address, count.index)}"
  count  = "${var.instances}"
}
