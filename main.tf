locals {
  postfix            = var.name_postfix != "" ? var.name_postfix : random_id.id.hex
  planCredentialPort = replace(var.plan, "standalone", "") != var.plan ? "port" : "sentinel_port"
}

resource "random_id" "id" {
  byte_length = 4
}

resource "cloudfoundry_service_instance" "redis" {
  name        = "tf-redis-${local.postfix}"
  space       = var.cf_space_id
  tags        = var.tags
  json_params = var.json_params
  //noinspection HILUnresolvedReference
  service_plan                   = data.cloudfoundry_service.redis.service_plans[var.plan]
  replace_on_service_plan_change = true
  recursive_delete               = var.recursive_delete_service
}

resource "cloudfoundry_service_key" "key" {
  name             = "tf-key-${local.postfix}"
  service_instance = cloudfoundry_service_instance.redis.id
}

resource "cloudfoundry_app" "exporter" {
  name         = "tf-redis-exporter-${local.postfix}"
  space        = var.cf_space_id
  docker_image = var.exporter_image
  disk_quota   = var.exporter_disk_quota
  memory       = var.exporter_memory
  docker_credentials = {
    username = var.docker_username
    password = var.docker_password
  }
  environment = merge({
    //noinspection HILUnresolvedReference
    REDIS_ADDR = "redis://${cloudfoundry_service_key.key.credentials.hostname}:${cloudfoundry_service_key.key.credentials[local.planCredentialPort]}"
    //noinspection HILUnresolvedReference
    REDIS_PASSWORD = cloudfoundry_service_key.key.credentials.password
  }, var.exporter_environment)

  //noinspection HCLUnknownBlockType
  routes {
    route = cloudfoundry_route.exporter.id
  }
  labels = {
    "variant.tva/exporter" = true,
  }
  annotations = {
    "prometheus.exporter.type" = "redis_exporter"
    "prometheus.exporter.port" = "9121"
    "prometheus.exporter.path" = "/scrape"
    "prometheus.targets.port"  = "9122"
    "prometheus.targets.path"  = "/targets"
  }
}

resource "cloudfoundry_route" "exporter" {
  domain   = data.cloudfoundry_domain.apps_internal_domain.id
  space    = var.cf_space_id
  hostname = "tf-redis-exporter-${local.postfix}"
}
