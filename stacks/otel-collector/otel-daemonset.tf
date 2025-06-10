resource "kubernetes_config_map_v1" "collector_daemonset" {
  metadata {
    name      = "otel-daemon-config"
    namespace = kubernetes_namespace.network.metadata[0].name
  }

  data = {
    "config.yaml" = file("${path.module}/otel-daemonset.yaml")
  }
}

resource "kubernetes_daemon_set_v1" "collector" {
  metadata {
    name      = "otel-daemon"
    namespace = kubernetes_namespace.network.metadata[0].name
    labels = {
      app       = "opentelemetry"
      component = "otel-daemon"
    }
  }

  spec {
    selector {
      match_labels = {
        app       = "opentelemetry"
        component = "otel-daemon"
      }
    }
    min_ready_seconds = 5
    template {
      metadata {
        labels = {
          app       = "opentelemetry"
          component = "otel-daemon"
        }
      }
      spec {
        container {
          name  = "otel-collector"
          image = "${var.docker_repositories.docker_hub}/otel/opentelemetry-collector-contrib:latest"

          # TODO
          security_context {
            privileged                 = true
            allow_privilege_escalation = true
            run_as_user                = 0
            run_as_group               = 0
            capabilities {
              add = ["SYS_ADMIN", "DAC_READ_SEARCH"]
            }
          }

          volume_mount {
            name       = "otel-daemon-config"
            mount_path = "/etc/otelcol-contrib/config.yaml"
            sub_path   = "config.yaml"
            read_only  = true
          }

          volume_mount {
            name       = "varlogpods"
            mount_path = "/var/log/pods"
            read_only  = true
          }

          volume_mount {
            name       = "varlibdockercontainers"
            mount_path = "/var/lib/docker/containers"
            read_only  = true
          }

          volume_mount {
            name              = "hostfs"
            mount_path        = "/hostfs"
            read_only         = true
            mount_propagation = "HostToContainer"
          }

          env {
            name = "MY_POD_IP"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }
          env {
            name = "K8S_NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
        }

        volume {
          name = "otel-daemon-config"
          config_map {
            name = "otel-daemon-config"
          }
        }

        volume {
          name = "varlogpods"
          host_path {
            path = "/var/log/pods"
          }
        }

        volume {
          name = "varlibdockercontainers"
          host_path {
            path = "/var/lib/docker/containers"
          }
        }

        volume {
          name = "hostfs"
          host_path {
            path = "/"
          }
        }

      }
    }
  }

  # depends_on = [ kubernetes_config_map_v1.collector_daemonset ]
}
