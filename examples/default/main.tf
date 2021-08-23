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
