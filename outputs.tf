locals {
  has_hash     = length(lookup(var.env_vars, "admin_pw_hash", "")) > 0
  vm_public_ip = google_compute_instance.instance.network_interface[0].access_config[0].nat_ip
  host_url     = lookup(
    var.env_vars,
    "access_server_link.initial_configuration.deployment_name",
    local.vm_public_ip
  )
}

output "site_url" {
  description = "Site Url"
  value       = "https://${local.host_url}:443/"
}

output "admin_url" {
  description = "Admin Url"
  value       = "https://${local.host_url}:943/admin"
}

output "admin_user" {
  description = "Username for Admin password."
  value       = "openvpn"
}

output "admin_password" {
  description = "Password for Admin."
  value       = local.has_hash ? null : local.admin_pw
  sensitive   = true
}

output "instance_self_link" {
  description = "Self-link for the compute instance."
  value       = google_compute_instance.instance.self_link
}
