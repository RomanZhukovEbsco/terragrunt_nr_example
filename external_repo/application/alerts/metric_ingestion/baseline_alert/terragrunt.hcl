locals {
  dest = {
    opsgenie_new_relic_sre     = data.newrelic_notification_destination.opsgenie_new_relic_sre.id
    opsgenie_new_relic_general = data.newrelic_notification_destination.opsgenie_new_relic_general.id
  }
  metric_ingestion_baseline_alert_enabled_default               = false
  metric_ingestion_baseline_aggregation_timer_default           = 1
  metric_ingestion_critical_baseline_threshold_default          = 1
  metric_ingestion_critical_baseline_threshold_duration_default = 1
}


resource "newrelic_nrql_alert_condition" "stnd_metric_ingestion_baseline_cond" {
  policy_id           = newrelic_alert_policy.stnd_metric_ingestion_baseline_pol.policy_id
  name                = "${inputs.name} Standard Metric ingestion baseline Alert"
  type                = "baseline"
  baseline_direction  = "upper_and_lower"
  description         = "Alert when ingestion of metric exceeds the baseline critical value ${var.alert_settings.metric_ingestion_critical_baseline_threshold}"
  runbook_url         = "https://eis.atlassian.net/wiki/x/AYBxNg"
  enabled             = tobool(coalesce(try(inputs.metric_ingestion_baseline_alert_enabled, local.metric_ingestion_baseline_alert_enabled_default)))
  expiration_duration = 86400
  fill_option         = "none"
  aggregation_method  = "event_timer"
  aggregation_timer   = coalesce(try(inputs.metric_ingestion_baseline_aggregation_timer), local.metric_ingestion_baseline_aggregation_timer_default)

  nrql {
    query = "FROM NrIngestedBytes SELECT rate(sum(ingested_bytes_metric)/1e9, ${coalesce(try(inputs.alert_settings.metric_ingestion_baseline_rate_duration), local.metric_ingestion_baseline_rate_duration_default)}) where usage.metric not in ('ApmEvents', 'BrowserEvents', 'InfraHost', 'InfraProcess', 'Tracing') and usage.event.type not in ('Process', 'NFSSample') WHERE appName='${each.value.name}'"
  }

  critical {
    operator              = "above"
    threshold             = coalesce(try(inputs.metric_ingestion_critical_baseline_threshold, local.metric_ingestion_critical_baseline_threshold_default))
    threshold_duration    = coalesce(try(inputs.metric_ingestion_critical_baseline_threshold_duration, local.metric_ingestion_critical_baseline_threshold_duration_default))
    threshold_occurrences = "all"
  }
}

# Create tags for the alert
resource "newrelic_entity_tags" "stnd_metric_ingestion_baseline_cond" {
  guid = newrelic_nrql_alert_condition.stnd_metric_ingestion_baseline_cond[each.key].entity_guid

  tag {
    key    = "owner"
    values = ["${inputs.owner}"]
  }

  tag {
    key    = "app"
    values = ["${inputs.name}"]
  }
}

resource "newrelic_alert_policy" "stnd_metric_ingestion_baseline_pol" {
  name = "${inputs
  .name} Standard Metric ingestion baseline Alert"
  incident_preference = "PER_CONDITION"
}

