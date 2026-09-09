locals {
  bootstrap = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    ssh_public_key = var.ssh_public_key
    build_jobs     = var.build_jobs
    verify_script  = base64encode(file("${path.module}/../scripts/verify.sh"))
  })
}

resource "digitalocean_ssh_key" "verifier" {
  name       = "${var.name}-key"
  public_key = trimspace(var.ssh_public_key)
}

resource "digitalocean_droplet" "verifier" {
  name       = var.name
  region     = var.region
  size       = var.size
  image      = var.image
  monitoring = true
  ipv6       = false
  ssh_keys   = [digitalocean_ssh_key.verifier.fingerprint]
  user_data  = local.bootstrap
  tags       = ["lean-verification", "ephemeral"]

  lifecycle {
    precondition {
      condition     = var.size != "s-1vcpu-1gb"
      error_message = "The verification workload cannot run on a 1 GiB Droplet."
    }
  }
}

resource "digitalocean_firewall" "verifier" {
  name        = "${var.name}-firewall"
  droplet_ids = [digitalocean_droplet.verifier.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = [var.admin_cidr]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

