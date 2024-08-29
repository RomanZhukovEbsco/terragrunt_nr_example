terraform {
  source = "./alerts/metric_ingestion/baseline_alert"
}

terraform {
  source = "./alerts/metric_ingestion/static_alert"
}

// inputs = {
// name                                                  = string
// owner                                                 = string
// metric_ingestion_baseline_alert_enabled               = optional(bool)
// metric_ingestion_baseline_rate_duration               = optional(string) # '1 hour' | '1 day' | '1 week' | '1 month'
// metric_ingestion_baseline_aggregation_timer           = optional(number)
// metric_ingestion_critical_baseline_threshold          = optional(number)
// metric_ingestion_critical_baseline_threshold_duration = optional(number)
// # Static
// metric_ingestion_static_alert_enabled               = optional(bool)
// metric_ingestion_static_rate_duration               = optional(string) # '1 hour' | '1 day' | '1 week' | '1 month'
// metric_ingestion_static_aggregation_timer           = optional(number)
// metric_ingestion_critical_static_threshold          = optional(number)
// metric_ingestion_critical_static_threshold_duration = optional(number)
// }
