locals {
  postfix = var.name_postfix != "" ? var.name_postfix : random_id.id.hex
}

resource "random_id" "id" {
  byte_length = 8
}

resource "cloudfoundry_service_instance" "redis" {
  name  = "tf-redis-${local.postfix}"
  space = var.cf_space_id
  //noinspection HILUnresolvedReference
  service_plan                   = data.cloudfoundry_service.redis.service_plans[var.plan]
  replace_on_service_plan_change = true
}

resource "cloudfoundry_service_key" "key" {
  name             = "key"
  service_instance = cloudfoundry_service_instance.redis.id
}

resource "cloudfoundry_app" "exporter" {
  name         = "tf-redis-exporter-${local.postfix}"
  space        = var.cf_space_id
  docker_image = var.exporter_image
  disk_quota   = var.exporter_disk_quota
  memory       = var.exporter_memory
  environment = merge({
    //noinspection HILUnresolvedReference
    //REDIS_ADDR = "redis://${cloudfoundry_service_key.key.credentials.hostname}:${cloudfoundry_service_key.key.credentials.sentinel_port}"
    REDIS_ADDR = "172.19.28.27:6379"
    //noinspection HILUnresolvedReference
    REDIS_PASSWORD = cloudfoundry_service_key.key.credentials.password
  }, var.exporter_environment)

  //noinspection HCLUnknownBlockType
  routes {
    route = cloudfoundry_route.exporter.id
  }
  labels = {
    "prometheus.io/exporter" = true,
  }
  annotations = {
    "prometheus.exporter.group"    = "redis_exporter"
    "prometheus.exporter.port"     = "9121"
    "prometheus.exporter.scrape"   = "/scrape"
    "prometheus.discovery.port"    = "9122"
    "prometheus.discovery.targets" = "/targets"
  }
}

resource "cloudfoundry_route" "exporter" {
  domain   = data.cloudfoundry_domain.apps_internal_domain.id
  space    = var.cf_space_id
  hostname = "tf-redis-exporter-${local.postfix}"
}