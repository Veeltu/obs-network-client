# https://docs.cilium.io/en/latest/network/servicemesh/ingress/#reference

# https://doc.traefik.io/traefik/routing/providers/kubernetes-gateway/
# https://gateway-api.sigs.k8s.io/guides/simple-gateway/
resource "kubernetes_manifest" "otel_gateway" {
  field_manager {
    force_conflicts = true
  }
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1beta1"
    kind       = "Gateway"
    metadata = {
      name      = "otel"
      namespace = kubernetes_namespace.otel_collector.metadata.0.name
    }

    spec = {
      gatewayClassName = "traefik"

      # Only Routes from the same namespace are allowed.
      listeners = concat(
        [
          {
            name     = "web"
            port     = 8000
            protocol = "HTTP"
            allowedRoutes = {
              namespaces = {
                from = "Selector"
                selector = {
                  matchLabels = {
                    shared-gateway-access = "true"
                  }
                }
              }
            }
          },
          {
            name     = "websecure"
            port     = 8443
            protocol = "HTTPS"
            tls = {
              mode            = "Terminate"
              certificateRefs = [for k in local.certs : { name = replace(k, ".", "-") }]
            }
            allowedRoutes = {
              namespaces = {
                from = "Selector"
                selector = {
                  matchLabels = {
                    shared-gateway-access = "true"
                  }
                }
              }
            }
          }
        ],
        [
          for key, route in local.tcpRoutes : merge({
            name     = key
            protocol = lookup(route, "protocol", "TCP")
            port     = route.port
            allowedRoutes = {
              kinds = [
                {
                  kind = "TCPRoute"
                }
              ]
            }
            },
            lookup(route, "tls", null) == null ? {} : {
              tls = route.tls
            }
          )
      ])
    }
  }
}

# resource "kubernetes_manifest" "syslogtcp_route" {
#   for_each = local.tcpRoutes
#   manifest = {
#     apiVersion = "gateway.networking.k8s.io/v1alpha2"
#     kind       = lookup(each.value, "ssl", {mode="Terminate"})["mode"] == "Passthrough" ? "TLSRoute" : "TCPRoute"
#     metadata = {
#       name      = each.key
#       namespace = kubernetes_namespace.otel_collector.metadata.0.name
#     }
#     spec = {
#       parentRefs = [
#         {
#           name        = "otel"
#           sectionName = each.key
#         }
#       ]
#       rules = [
#         {
#           backendRefs = [
#             {
#               name = kubernetes_service_v1.collector.metadata.0.name
#               port = each.value.port
#             }
#           ]
#         }
#       ]
#     }
#   }
# }
