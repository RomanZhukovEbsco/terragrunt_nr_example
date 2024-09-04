include "root" {
  path = find_in_parent_folders()
}

import "app" {
  config_path = "../../../external_repo/application/terragrunt.hcl"
}
import "env" {
  config_path = "../_env/env.hcl"
}

terraform {
  source = "../../../../external_repo/application/"
}

locals = {
  name  = "appd-test"
  owner = "obsv.pipe-fiction"
}

app_specific_settings = {
  metric_ingestion_static_alert_enabled = true
}

inputs = merge(
  locals,
  env.locals,
  app.inputs,
  app_specific_settings
)

module "appdtest_sandbox_application" {
  source = "./modules/alerts/metric_ingestion/baseline_alert" #git::git@github.com:alerts/baseline_alert.git//app?ref=v1.0.4"

  inputs = inputs
}