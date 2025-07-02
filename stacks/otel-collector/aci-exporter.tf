

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
          image = "takalele/aci-exporter:latest"
          port {
            container_port = 9300
            name           = "http-metrics"
            protocol       = "TCP"
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
