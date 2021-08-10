data "cloudfoundry_org" "org" {
  name = var.cf_org_name
}

data "cloudfoundry_space" "space" {
  org  = data.cloudfoundry_org.org.id
  name = var.cf_space_name
}

module "thanos" {
  source = "philips-labs/thanos/cloudfoundry"

  cf_org_name = "test"
  cf_space_id = data.cloudfoundry_space.space.id
}

module "redis" {
  source      = "philips-labs/redis-service/hsdp"
  cf_space_id = data.cloudfoundry_space.space.id
}

resource "cloudfoundry_network_policy" "redis_exporter" {
  policy {
    source_app      = module.thanos.thanos_app_id
    destination_app = module.redis.metrics_app_id
    port            = module.redis.metrics_port
  }
}
