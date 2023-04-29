terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }
}

resource "digitalocean_kubernetes_cluster" "main" {
  name    = "do-kubernetes"
  region  = "ams3"
  version = "1.26.3-do.0"
  node_pool {
    name       = "default"
    size       = "s-2vcpu-2gb"
    node_count = 1
  }
}

provider "kubernetes" {
  host                   = digitalocean_kubernetes_cluster.main.endpoint
  cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
  token                  = digitalocean_kubernetes_cluster.main.kube_config.0.token
}

provider "helm" {
  kubernetes {
    host                   = digitalocean_kubernetes_cluster.main.endpoint
    cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
    token                  = digitalocean_kubernetes_cluster.main.kube_config.0.token
  }
}

resource "kubernetes_secret" "test" {
  depends_on = [digitalocean_kubernetes_cluster.main]
  metadata {
    name = "test"
  }
  data = {
    "hello" : "world"
  }
}

resource "helm_release" "ingress_nginx" {
  depends_on = [digitalocean_kubernetes_cluster.main]
  name       = "ingress-nginx"
  namespace  = "default"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.5.2"
  values = [<<-EOF
    controller:
      replicaCount: 1
  EOF
  ]
}
