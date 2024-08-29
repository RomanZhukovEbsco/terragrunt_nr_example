locals = {
  alert_properties = {
    metric_ingestion_static_alert_enabled_default_value         = false
    metric_ingestion_static_rate_duration_default               = "1 day"
    metric_ingestion_static_aggregation_timer_default           = 60 # 60 <-> 1200
    metric_ingestion_critical_static_threshold_default          = 10
    metric_ingestion_critical_static_threshold_duration_default = 300 # Must be divisible by 60
  }
}

resource "newrelic_nrql_alert_condition" "stnd_metric_ingestion_threshold_cond" {
  policy_id           = newrelic_alert_policy.stnd_metric_ingestion_threshold_pol[each.key].id
  name                = "${inputs.name} Standard Metric ingestion threshold Alert"
  type                = "static"
  description         = "Alert when ingestion of metric exceeds the threshold critical value ${coalesce(try(inputs.metric_ingestion_critical_static_threshold, local.metric_ingestion_critical_static_threshold_default))}"
  runbook_url         = "https:eis.atlassian.net/wiki/x/AwAHMg"
  enabled             = true
  expiration_duration = 86400 # 30sec <-> 2 days (172800)
  fill_option         = "none"
  aggregation_method  = "event_timer"
  aggregation_timer   = coalesce(try(inputs.metric_ingestion_static_aggregation_timer, local.alert_properties.metric_ingestion_static_aggregation_timer_default))

  nrql {
    query = "FROM NrIngestedBytes SELECT rate(sum(ingested_bytes_metric) / 1e9, $ {coalesce(try(inputs.metric_ingestion_static_rate_duration, local.metric_ingestion_static_rate_duration_default)) }) where usage.metric not in(' ApmEvents ', ' BrowserEvents ', ' InfraHost ', ' InfraProcess ', ' Tracing ') and usage.event.type not in(' Process ', ' NFSSample ') WHERE appName = ' $ { inputs.name } ' "
  }

  critical {
    operator              = " above "
    threshold             = coalesce(try(inputs.alert_properties[" metric_ingestion_critical_static_threshold "], local.metric_ingestion_critical_static_threshold_default))
    threshold_duration    = coalesce(try(inputs.alert_properties[" metric_ingestion_critical_static_threshold_duration "], local.metric_ingestion_critical_static_threshold_duration_default), local.metric_ingestion_critical_static_threshold_duration_default)
    threshold_occurrences = " all "
  }
}

# Create tags for the alert
resource " newrelic_entity_tags " " stnd_metric_ingestion_threshold_cond " {
  for_each = inputs.owner
  guid     = newrelic_nrql_alert_condition.stnd_metric_ingestion_threshold_cond[each.key].entity_guid

  tag {
    key    = " owner "
    values = [" $ { inputs.owner } "]
  }

  tag {
    key    = " app "
    values = [" $ { inputs.name } "]
  }
}

resource " newrelic_alert_policy " " stnd_metric_ingestion_threshold_pol " {
  for_each            = local.all_envs
  name                = " $ { inputs.name } Standard Metric ingestion threshold Alert "
  incident_preference = " PER_CONDITION "
}

resource " newrelic_workflow " " stnd_metric_ingestion_threshold_wkfl " {
  for_each              = local.all_envs
  name                  = " $ { inputs.name } Standard Metric Ingestion Workflow "
  muting_rules_handling = " NOTIFY_ALL_ISSUES "

  issues_filter {
    name = " Metric Ingestion Workflow Filter "
    type = " FILTER "

    predicate {
      attribute = " labels.policyIds "
      operator  = " EXACTLY_MATCHES "
      values    = [newrelic_alert_policy.stnd_metric_ingestion_threshold_pol[each.key].id]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.stnd_opsgenie_new_relic_metric_ingest_chnl[each.key].id
  }
}

resource " newrelic_notification_channel " " stnd_opsgenie_new_relic_metric_ingest_chnl " {
  name           = " opsgenie channel metric ingest "
  type           = " WEBHOOK "
  destination_id = var.dest[" opsgenie_new_relic_general "]
  product        = " IINT "
  #  TODO: verify settings and payload
  property {
    key   = " payload "
    label = " Payload Template "
    value = <<-EOT
    {
       " tags ": {{#if issueClosedAtUtc }} [] {{ else }} [
           {{ json accumulations.tag.owner.[0] }},
           {{ json accumulations.tag.app.[0] }}
       ]{{/if}},
       " payload ": {
         " app ": {{ json accumulations.tag.app.[0] }},
         " opsgenie_alert_name ": " Metric Ingest Alrt ",
         " current_state ": {{#if issueClosedAtUtc }} " closed " {{ else if issueAcknowledgedAt }} " acknowledged " {{ else }} " open "{{/if }},
         " details ": " { { #each annotations.title }} {{ this }}<br>{{#unless @last }} {{/unless }} {{/each }}",
      "event_type" : "Issue",
      "incident_id" : { { json issueId } },
      "incident_url" : { { json issuePageUrl } },
      "owner" : "{{ accumulations.tag.owner.[0] }}",
      "policy_name" : { { json accumulations.policyName.[0] } },
      "runbook_url" : { { json accumulations.runbookUrl.[0] } },
      "severity" : { { #eq "HIGH" priority }} "P3" {{ else }} "P1" {{/eq }},
        "nr_account" : { { json accumulations.tag.account.[0] } },
        "timestamp" : { { #if closedAt }} {{ closedAt }} {{ else if acknowledgedAt }} {{ acknowledgedAt }} {{ else }} {{ createdAt }} {{/if }}
          }
        }
        EOT
  }
}
