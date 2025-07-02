# # temporarily as cilium doesnt seem to fully support what we need (yet) in the cluster config

# # locals {
# #   certs = toset([
# #     "gw.observability.test.pndrs.de",
# #     #"opsgw2.ctn-h.test.pndrs.de", # for testing purposes so its tested with multiple already
# #   ])
# # }

resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"
    labels = {
      shared-gateway-access = "true"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["cattle.io/status"],
      metadata[0].annotations["lifecycle.cattle.io/create.namespace-auth"],
    ]
  }
}

# # https://github.com/traefik/traefik-helm-chart/blob/master/traefik/values.yaml
# resource "helm_release" "traefik" {
#   namespace  = kubernetes_namespace.traefik.metadata[0].name
#   name       = "traefik"
#   repository = "https://helm.traefik.io/traefik"
#   chart      = "traefik"
#   version    = "32.1.1"

#   # If default_values == "" then apply default values from the chart if its anything else
#   # then apply values file using the values_file input variable
#   values = [
#     yamlencode({
#       image = {
#         registry = var.docker_repositories.docker_hub
#       }
#       deployment = {
#         replicas = 1
#       }
#       ingressClass = {
#         enabled = true
#       }
#       logs = {
#         general = {
#           format = "json"
#           level  = "DEBUG"
#         }
#         access = {
#           enabled = true
#           format  = "json"
#         }
#       }
#       gateway = {
#         enabled = false
#         listeners = {
#           web = {
#             port     = 8000
#             protocol = "HTTP"
#           }
#           websecure = {
#             port     = 8443
#             protocol = "HTTPS"
#             certificateRefs = [
#               for k in local.certs :
#               {
#                 name = replace(k, ".", "-")
#               }
#             ]
#           }
#         }
#       }
#       providers = {
#         # https://doc.traefik.io/traefik/providers/kubernetes-gateway/
#         kubernetesGateway = {
#           enabled             = true
#           experimentalChannel = true
#         }
#         kubernetesIngress = {
#           enabled = false
#         }
#         kubernetesCRD = {
#           enabled = true
#         }
#       }
#       service = {
#         annotations = {
#           "external-dns.alpha.kubernetes.io/hostname" = "gw.observability.test.pndrs.de"
#         }
#       }
#       ports = merge({
#         # example:
#         # https://github.com/traefik/traefik-helm-chart/blob/045b7355d0890fc12ae92d2253295cf98e716e39/traefik/values.yaml#L614
#         for key, val in local.tcpRoutes : key => {
#           name        = key
#           port        = val.port
#           exposedPort = val.port
#           protocol    = "TCP"
#           expose = {
#             default = true
#           }
#         }
#         }, {

#       })
#     })
#   ]
# }


# # resource "kubernetes_manifest" "certs" {
# #   for_each = local.certs
# #   manifest = {
# #     apiVersion = "cert-manager.io/v1"
# #     kind       = "Certificate"
# #     metadata = {
# #       name      = replace(each.key, ".", "-")
# #       namespace = kubernetes_namespace.otel_collector.metadata.0.name
# #     }
# #     spec = {
# #       dnsNames = [
# #         each.key
# #       ]
# #       duration = "8760h0m0s"
# #       issuerRef = {
# #         kind = "ClusterIssuer"
# #         name = "edp-internal"
# #       }
# #       secretName = replace(each.key, ".", "-")
# #     }
# #   }

# #   timeouts {
# #     create = "10m"
# #     delete = "5m"
# #   }
# # }
