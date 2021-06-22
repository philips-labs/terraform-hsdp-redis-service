data "hsdp_config" "cf" {
  service = "cf"
}

data "cloudfoundry_domain" "apps_internal_domain" {
  name = "apps.internal"
}

data "cloudfoundry_service" "redis" {
  name = "hsdp-redis-db"
}
