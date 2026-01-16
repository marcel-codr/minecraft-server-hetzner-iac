output "cloud_init_count" {
  description = "Number of generated cloud-init payloads (java)"
  value       = length(local.cloud_inits)
}
