# envs for testing

resource "kubernetes_secret_v1" "kafka_credentials" {
  metadata {
    name      = "kafka-credentials"
    namespace = kubernetes_namespace.network.metadata[0].name
  }

  data = {
    username = "test-kafka-user"
    password = "test-kafka-password"
  }

  type = "Opaque"
}

resource "kubernetes_secret_v1" "snmp_credentials" {
  metadata {
    name      = "snmp-credentials"
    namespace = kubernetes_namespace.network.metadata[0].name
  }

  data = {
    "auth-password"    = "test-snmp-auth-password"
    "privacy-password" = "test-snmp-privacy-password"
  }

  type = "Opaque"
}
