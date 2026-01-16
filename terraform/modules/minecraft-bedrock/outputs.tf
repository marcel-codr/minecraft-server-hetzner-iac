output "cloud_init_count" {
  description = "Number of generated cloud-init payloads (bedrock)"
  value       = length(local.cloud_inits)
}
