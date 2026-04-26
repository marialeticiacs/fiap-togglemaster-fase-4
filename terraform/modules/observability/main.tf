# Instala o Prometheus e o Grafana juntos (Kube-Prometheus-Stack)
resource "helm_release" "prometheus_grafana" {
  name             = "prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "observability"
  create_namespace = true
  version          = "56.6.2" # Versão estável

  # Desabilita alertas padrão muito ruidosos para o Tech Challenge
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

  # Configura o Loki para enviar os logs para o Grafana que acabamos de instalar
  set {
    name  = "grafana.enabled"
    value = "false" # Usamos o Grafana do Kube-Prometheus-Stack
  }
}

# Instala o OpenTelemetry Collector (O "Coração" do monitoramento)
resource "helm_release" "otel_collector" {
  name       = "otel-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  namespace  = "observability"
  version    = "0.80.1"

  # Aqui nós configuramos o OTel para receber dados das suas aplicações
  # e exportar (enviar) os Traces para o Datadog!
  values = [
    <<-EOT
    mode: daemonset
    image:
      repository: "otel/opentelemetry-collector-contrib" # Usa a versão com suporte ao Datadog
      tag: "0.95.0"
    config:
      exporters:
        datadog:
          api:
            site: datadoghq.com
            key: "bba898ca9ad9005e04e7ed325e9afdcd"
      receivers:
        otlp:
          protocols:
            grpc:
              endpoint: 0.0.0.0:4317
            http:
              endpoint: 0.0.0.0:4318
      service:
        pipelines:
          traces:
            receivers: [otlp]
            exporters: [datadog]
    EOT
  ]
}