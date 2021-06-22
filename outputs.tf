output "service_id" {
  description = "The service id"
  value       = cloudfoundry_service_instance.redis.id
}

output "metrics_host" {
  description = "The exporter metrics internal hostname"
  //noinspection HILUnresolvedReference
  value = join("", cloudfoundry_route.exporter.*.endpoint)
}

output "metrics_port" {
  description = "The exporter metrics internal port"
  value       = "9121"
}

output "metrics_app_id" {
  description = "The metrics app ID"
  value       = cloudfoundry_app.exporter.id
}
