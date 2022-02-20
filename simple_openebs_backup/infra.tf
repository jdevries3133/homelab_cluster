terraform {

  backend "s3" {
    bucket = "my-sites-terraform-remote-state"
    key    = "backup_test"
    region = "us-east-2"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.8.0"
    }

  }
}

provider "kubernetes" {
  config_path = "~/.kube/prod_config"
}

resource "kubernetes_namespace" "backup_test" {
  metadata {
    name = "backup-test"
  }
}


resource "kubernetes_deployment" "backup_test" {
  metadata {
    name      = "backup-test-deployment"
    namespace = kubernetes_namespace.backup_test.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "backup-test"
      }
    }

    template {
      metadata {
        labels = {
          app = "backup-test"
        }
      }
      spec {
        container {
          name  = "backup-test"
          image = "jdevries3133/backup_test:latest"
          volume_mount {
            mount_path = "/local"
            name       = "loc"
          }
          volume_mount {
            mount_path = "/replicated"
            name       = "repl"
          }
        }

        // local volume
        volume {
          name = "loc"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.local.metadata.0.name
          }
        }

        // replicated volume
        volume {
          name = "repl"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.replicated.metadata.0.name
          }
        }
      }
    }
  }
}


resource "kubernetes_persistent_volume_claim" "local" {
  metadata {
    name      = "local"
    namespace = kubernetes_namespace.backup_test.metadata[0].name
  }
  spec {
    resources {
      requests = {
        storage = "200Mi"
      }
    }
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-hostpath"
  }
}


resource "kubernetes_persistent_volume_claim" "replicated" {
  metadata {
    name      = "replicated"
    namespace = kubernetes_namespace.backup_test.metadata[0].name
  }
  spec {
    resources {
      requests = {
        storage = "200Mi"
      }
    }
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-jiva-csi-default"
  }
}
