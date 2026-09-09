output "ipv4_address" {
  value       = digitalocean_droplet.verifier.ipv4_address
  description = "Public address of the ephemeral verifier."
}

output "droplet_id" {
  value       = digitalocean_droplet.verifier.id
  description = "Droplet ID to record with the run and destroy afterward."
}

output "ssh_command" {
  value       = "ssh verifier@${digitalocean_droplet.verifier.ipv4_address}"
  description = "SSH command (subject to your local key selection)."
}

