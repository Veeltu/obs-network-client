



resource "tls_private_key" "gw_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "gw_cert" {
  private_key_pem = tls_private_key.gw_key.private_key_pem

  subject {
    common_name  = "gw.observability.test.pndrs.de"
    organization = ["pndrs"]
  }

  validity_period_hours = 8760 # 1 rok
  is_ca_certificate     = false

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = ["gw.observability.test.pndrs.de"]
}

resource "kubernetes_secret" "gw_tls" {
  metadata {
    name      = "gw-observability-tls"
    namespace = kubernetes_namespace.network.metadata[0].name
  }

  type = "kubernetes.io/tls"
  data = {
    "tls.crt" = tls_self_signed_cert.gw_cert.cert_pem
    "tls.key" = tls_private_key.gw_key.private_key_pem
  }

  depends_on = [kubernetes_namespace.network]
}



resource "kubernetes_secret" "kafka_credentials" {
  metadata {
    name      = "kafka-credentials"
    namespace = "network"
  }

  data = {
    username = base64encode("testuser")
    password = base64encode("testpass")
  }

  type = "Opaque"
}

resource "kubernetes_secret" "snmp_credentials" {
  metadata {
    name      = "snmp-credentials"
    namespace = "network"
  }

  data = {
    "auth-password"    = base64encode("snmpauth")
    "privacy-password" = base64encode("snmppriv")
  }

  type = "Opaque"
}
