terraform {
  required_version = ">= 0.15.1"

  required_providers {
    hsdp = {
      source  = "philips-software/hsdp"
      version = ">= 0.17.0"
    }
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = ">= 0.14.2"
    }
  }
}
