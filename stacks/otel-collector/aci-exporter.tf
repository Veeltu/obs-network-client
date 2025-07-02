resource "kubernetes_config_map" "aci_exporter_config" {
  metadata {
    name      = "aci-exporter-config"
    namespace = kubernetes_namespace.network.metadata[0].name
  }
  data = {
    "config.yaml" = <<-EOT
fabrics:
  myfabric:
    apic: https://apic.example.com
    username: admin
    password: haslo123
    query_groups:
      - default
EOT
  }
}

resource "kubernetes_deployment" "aci_exporter" {
  metadata {
    name      = "aci-exporter"
    namespace = kubernetes_namespace.network.metadata[0].name
    labels = {
      app = "aci-exporter"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "aci-exporter"
      }
    }
    template {
      metadata {
        labels = {
          app = "aci-exporter"
        }
      }
      spec {
        container {
          name  = "aci-exporter"
          image = "opsdis/aci-exporter:latest"
          args = [
            "--config.file=/dps/monitoring/mon_aci_exporter/etc/aci-exporter/config.yaml"
          ]
          port {
            container_port = 9300
            name           = "http-metrics"
            protocol       = "TCP"
          }
          volume_mount {
            name       = "aci-exporter-config"
            mount_path = "/etc/aci-exporter"
            read_only  = true
          }
        }
        volume {
          name = "aci-exporter-config"
          config_map {
            name = kubernetes_config_map.aci_exporter_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "aci_exporter" {
  metadata {
    name      = "aci-exporter"
    namespace = kubernetes_namespace.network.metadata[0].name
  }
  spec {
    selector = {
      app = "aci-exporter"
    }
    port {
      name        = "http-metrics"
      port        = 9300
      target_port = 9300
      protocol    = "TCP"
    }
    type = "ClusterIP"
  }
}
