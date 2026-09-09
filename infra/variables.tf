variable "name" {
  description = "Droplet and firewall name."
  type        = string
  default     = "lean-fluid-verifier"
}

variable "region" {
  description = "DigitalOcean region with the selected size available."
  type        = string
  default     = "sfo3"
}

variable "size" {
  description = "Droplet slug. Default targets 24 vCPU / 192 GiB RAM. Confirm availability with: doctl compute size list."
  type        = string
  default     = "m-24vcpu-192gb"
}

variable "image" {
  description = "Pinned-by-name Ubuntu image; record the resolved image metadata in the result bundle."
  type        = string
  default     = "ubuntu-24-04-x64"
}

variable "ssh_public_key" {
  description = "Public key installed for the verifier user. Never supply a private key."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256) ", trimspace(var.ssh_public_key)))
    error_message = "ssh_public_key must be an OpenSSH public key."
  }
}

variable "admin_cidr" {
  description = "Single trusted IPv4 CIDR allowed to SSH, normally your public IP with /32."
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0)) && var.admin_cidr != "0.0.0.0/0"
    error_message = "admin_cidr must be a valid, restricted CIDR; 0.0.0.0/0 is intentionally rejected."
  }
}

