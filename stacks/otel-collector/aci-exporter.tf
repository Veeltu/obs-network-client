resource "kubernetes_config_map" "aci_exporter_config" {
  metadata {
    name      = "aci-exporter-config"
    namespace = kubernetes_namespace.network.metadata[0].name
  }
  data = {
    "config.yaml" = file("aci-exporter-config.yaml")
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
          name              = "aci-exporter"
          image             = "europe-west3-docker.pkg.dev/nz-mgmt-shared-artifacts-8c85/ghcr-io/opsdis/aci-exporter:latest"
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 9643
            name           = "metrics"
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/aci-exporter"
          }

          volume_mount {
            name       = "config-d"
            mount_path = "/etc/aci-exporter/config.d"
          }

          env {
            name  = "ACI_EXPORTER_CONFIG"
            value = "config.yaml"
          }
        }

        volume {
          name = "config"

          config_map {
            name = kubernetes_config_map.aci_exporter_config.metadata[0].name
          }
        }

        volume {
          name = "config-d"

          empty_dir {}
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
      name        = "metrics"
      port        = 9643
      target_port = 9643
      # protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
