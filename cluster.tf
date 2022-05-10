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
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
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

provider "kubectl" {
  config_path = "~/.kube/config"
}


data "http" "certmanager" {
  url = "https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml"
}

resource "kubectl_manifest" "certmanager" {
  yaml_body = data.http.certmanager.body
}

resource "kubectl_manifest" "issuer" {
  yaml_body = file("./manifests/clusterissuer.yml")

  depends_on = [
    kubectl_manifest.certmanager
  ]
}

resource "kubectl_manifest" "kibana_ingress" {
  yaml_body = file("./manifests/kibana_ingress.yml")
}

resource "kubectl_manifest" "prometheus_ingress" {
  yaml_body = file("./manifests/prometheus_ingress.yml")
}


resource "kubectl_manifest" "nginx_service_monitor" {
  yaml_body = file("./manifests/nginx_service.yml")
}

resource "kubectl_manifest" "nginx_service" {
  yaml_body = file("./manifests/nginx_service_monitor.yml")
}

