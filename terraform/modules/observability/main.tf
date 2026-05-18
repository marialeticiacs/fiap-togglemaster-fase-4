# Instala o Prometheus e o Grafana juntos (Kube-Prometheus-Stack)
resource "helm_release" "prometheus_grafana" {
  name             = "prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "observability"
  create_namespace = true
  version          = "56.6.2"

  set {
    name  = "defaultRules.create"
    value = "false"
  }
}

# Instala o Loki (para Logs)
resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  namespace  = "observability"
  version    = "2.9.11"

  depends_on = [helm_release.prometheus_grafana]

  set {
    name  = "grafana.enabled"
    value = "false"
  }
}

# Instala o OpenTelemetry Collector
resource "helm_release" "otel_collector" {
  name             = "otel-collector"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  namespace        = "observability"
  version          = "0.110.0" 

  depends_on = [helm_release.prometheus_grafana]

  values = [
    <<-EOT
    mode: deployment
    
    # OBRIGATÓRIO PARA A VERSÃO 0.110.0:
    image:
      repository: "otel/opentelemetry-collector-contrib"
      tag: "0.100.0"
    
    config:
      exporters:
        datadog:
          api:
            site: "us5.datadoghq.com"
            key: "318300c42e161e9fc1a3e8330742d706"
      receivers:
        otlp:
          protocols:
            grpc:
              endpoint: 0.0.0.0:4317
            http:
              endpoint: 0.0.0.0:4318
      processors:
        batch: {}
      service:
        pipelines:
          traces:
            receivers: [otlp]
            processors: [batch]
            exporters: [datadog]
    EOT
  ]
}