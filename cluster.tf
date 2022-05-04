terraform {

  backend "s3" {
    bucket = "my-sites-terraform-remote-state"
    key    = "cluster"
    region = "us-east-2"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.7.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4.1"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "kubernetes_namespace" "openebs" {
  metadata {
    name = "openebs"
  }
}

resource "helm_release" "openebs" {
  name       = "openebs"
  namespace  = kubernetes_namespace.openebs.metadata.0.name
  repository = "https://openebs.github.io/charts"
  chart      = "openebs"
  version    = "3.2.0"

  set {
    name  = "jiva.enabled"
    value = true
  }
}


