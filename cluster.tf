terraform {
  backend "s3" {
    bucket = "my-sites-terraform-remote-state"
    key    = "cluster-2"
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

resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = "nginx-ingress"
  }
}

resource "helm_release" "nginx_ingress" {
  name = "nginx-ingress"
  namespace = kubernetes_namespace.nginx_ingress.metadata.0.name
  repository = "https://helm.nginx.com/stable"
  chart = "nginx-ingress"
  version = "0.16.0"

  set {
    // Using a DaemonSet ensures at least 1 runs per node, which means that any
    // worker node becomes a valid ingress recipient, which just makes life
    // simpler
    name = "controller.kind"
    value = "daemonset"
  }
  set {
    // This is typical for kubeadm clusters. The typical "LoadBalancer" type
    // is going to integrate with cloud providers. For an on-prem homelab
    // setup, we want the ingress to listen on ports on the node they are
    // running on
    name = "controller.service.type"
    value = "NodePort"
  }
  set {
    name = "controller.service.nodePorts.http"
    value = 80
  }
  set {
    name = "controller.service.nodePorts.http"
    value = 443
  }
}
