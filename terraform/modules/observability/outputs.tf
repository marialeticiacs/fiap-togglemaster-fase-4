output "grafana_namespace" {
  value = helm_release.prometheus_grafana.namespace
}