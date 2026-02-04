locals {
  vm_public_ip = google_compute_instance.instance.network_interface[0].access_config[0].nat_ip
}

output "site_url" {
  description = "Site Url"
  value       = "https://${local.vm_public_ip}:443/"
}

output "admin_url" {
  description = "Admin Url"
  value       = "https://${local.vm_public_ip}:943/admin"
}

output "admin_user" {
  description = "Username for Admin password."
  value       = "openvpn"
}

output "admin_password" {
  description = "Password for Admin."
  value       = local.admin_pw
  sensitive   = true
}

output "instance_self_link" {
  description = "Self-link for the compute instance."
  value       = google_compute_instance.instance.self_link
}
