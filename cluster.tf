terraform {
  backend "s3" {
    bucket = "my-sites-terraform-remote-state"
    key    = "cluster-3"
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
  name       = "nginx-ingress"
  namespace  = kubernetes_namespace.nginx_ingress.metadata.0.name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.3"
  set {
    name = "controller.service.type"
    value = "NodePort"
  }
  set {
    name = "controller.dnsPolicy"
    value = "ClusterFirstWithHostNet"
  }
  set {
    // Using a DaemonSet ensures at least 1 runs per node, which means that any
    // worker node becomes a valid ingress recipient, which just makes life
    // simpler
    name  = "controller.kind"
    value = "DaemonSet"
  }
  set {
    name = "controller.hostNetwork"
    value = true
  }
  // set {
  //   name = "controller.hostPort.enabled"
  //   value = true
  // }
  set {
    name = "controller.publishService.enabled"
    value = false
  }
  set {
    name = "controller.reportNodeInternalIp"
    value = true
  }
}

resource "kubernetes_namespace" "certmanager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "certmanager" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace.certmanager.metadata.0.name
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.11.1"

  set {
    name  = "installCRDs"
    value = true
  }
}

variable "letsencrypt_email" {
  type = string
}

// Affected by https://github.com/hashicorp/terraform-provider-kubernetes/issues/1367
// I just comment this guy out, then re-run tf apply; kind of gross but w/e
resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        email  = var.letsencrypt_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          // I am pretty sure the API key is what ends up being stored in
          // this secret, but I could be wrong.
          name = "letsencrypt-prod-api-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }
}
resource "kubernetes_namespace" "openebs" {
  metadata {
    name = "openebs"
  }
}

resource "helm_release" "openebs" {
  name       = "openebs"
  repository = "https://openebs.github.io/charts"
  chart      = "openebs"
  version    = "3.8.0"
  namespace  = kubernetes_namespace.openebs.metadata[0].name

  set {
    name  = "localprovisioner.deviceClass.enabled"
    value = false
  }
  set {
    name  = "localprovisioner.hostpathClass.enabled"
    value = false
  }
}

resource "kubernetes_storage_class" "local-ssd" {
  metadata {
    name = "local-ssd"
    annotations = {
      "openebs.io/cas-type"   = "local",
      "cas.openebs.io/config" = <<-EOT
      - name: StorageType
        value: "hostpath"
      - name: BasePath
        value: "/mnt/openebs-ssd"
      EOT
    }
  }
  storage_provisioner = "openebs.io/local"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"
}
