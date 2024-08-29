generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
  terraform {
    required_providers {
      newrelic = {
        source = "newrelic/newrelic"
      }
    }
  }
EOF
}