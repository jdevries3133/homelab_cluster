terraform {
  backend "s3" {
    bucket = "my-sites-terraform-remote-state"
    key    = "cluster-5"
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
  repository = "https://openebs.github.io/openebs"
  chart      = "openebs"
  version    = "4.1.2"
  namespace  = kubernetes_namespace.openebs.metadata[0].name

  set {
    name  = "localprovisioner.deviceClass.enabled"
    value = false
  }
  set {
    name  = "localprovisioner.hostpathClass.enabled"
    value = false
  }
  set {
    name = "mayastor.csi.node.kubeletDir"
    value = "/var/lib/kubelet"
  }
  set {
    name = "engines.replicated.mayastor.enabled"
    value = true
  }
}

resource "kubernetes_storage_class" "sql_db" {
  metadata {
    name = "sql-db"
  }
  parameters = {
    protocol = "nvmf"
    repl = "2"
    fsType = "xfs"
  }
  storage_provisioner = "io.openebs.csi-mayastor"
  reclaim_policy = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"
  allow_volume_expansion = true
}

resource "kubernetes_manifest" "nick_disk_0" {
  manifest = {
    apiVersion = "openebs.io/v1beta2"
    kind = "DiskPool"
    metadata = {
      name = "nick-0"
      namespace = kubernetes_namespace.openebs.metadata[0].name
    }
    spec = {
      node = "nick"
      // > Note that whilst the "disks" parameter accepts an array of values,
      // > the current version of Replicated PV Mayastor supports only one disk
      // > device per pool.
      //
      // https://openebs.io/docs/user-guides/replicated-storage-user-guide/replicated-pv-mayastor/rs-configuration#configure-pools

      disks = [
        "/dev/disk/by-id/ata-KINGSTON_SA400S37480G_50026B77856FCED7",
      ]
    }
  }
}

resource "kubernetes_manifest" "nick_disk_1" {
  manifest = {
    apiVersion = "openebs.io/v1beta2"
    kind = "DiskPool"
    metadata = {
      name = "nick-1"
      namespace = kubernetes_namespace.openebs.metadata[0].name
    }
    spec = {
      node = "nick"
      // > Note that whilst the "disks" parameter accepts an array of values,
      // > the current version of Replicated PV Mayastor supports only one disk
      // > device per pool.
      //
      // https://openebs.io/docs/user-guides/replicated-storage-user-guide/replicated-pv-mayastor/rs-configuration#configure-pools

      disks = [
        "/dev/disk/by-id/scsi-SATA_KINGSTON_SA400S3_50026B7785077865"
      ]
    }
  }
}

resource "kubernetes_manifest" "dweedledum_disk_pool" {
  manifest = {
    apiVersion = "openebs.io/v1beta2"
    kind = "DiskPool"
    metadata = {
      name = "dweedledum-sdb"
      namespace = kubernetes_namespace.openebs.metadata[0].name
    }
    spec = {
      node = "dweedledum"
      disks = [
        "/dev/disk/by-id/ata-KINGSTON_SA400S37480G_50026B7785076D69"
      ]
    }
  }
}

resource "kubernetes_manifest" "big_boi_disk_pool" {
  manifest = {
    apiVersion = "openebs.io/v1beta2"
    kind = "DiskPool"
    metadata = {
      name = "big-boi-sda"
      namespace = kubernetes_namespace.openebs.metadata[0].name
    }
    spec = {
      node = "big-boi"
      disks = [
        "/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B7783EF49E7"
      ]
    }
  }
}

resource "kubernetes_cluster_role_binding" "jack_admin" {
  metadata {
    name = "jack-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "cluster-admin"
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind = "User"
    name = "jack"
  }
}

// I haven't figured out the right scoped permissions, so for now I just
// uncomment this to escalate GitHub into god-mode whenver I want deployments
// to work, and I'll figure out how to scope it down later.
// resource "kubernetes_cluster_role_binding" "github_admin" {
//   metadata {
//     name = "github-admin"
//   }
//   role_ref {
//     api_group = "rbac.authorization.k8s.io"
//     kind = "ClusterRole"
//     name = "admin"
//   }
//   subject {
//     api_group = "rbac.authorization.k8s.io"
//     kind = "User"
//     name = "github"
//     namespace = "beancount"
//   }
// }
