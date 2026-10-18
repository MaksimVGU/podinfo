resource "yandex_iam_service_account" "kubernetes" {
  name        = "${var.project_name}-kubernetes"
  description = "Service account for managing the Podinfo Kubernetes cluster"
}

resource "yandex_iam_service_account" "nodes" {
  name        = "${var.project_name}-nodes"
  description = "Service account for Podinfo Kubernetes worker nodes"
}

resource "yandex_resourcemanager_folder_iam_member" "kubernetes_editor" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.kubernetes.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "nodes_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.nodes.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "kubernetes_vpc_public_admin" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.kubernetes.id}"
}

resource "yandex_kubernetes_cluster" "project" {
  name                    = "${var.project_name}-cluster"
  description             = "Podinfo Kubernetes cluster managed by Terraform"
  network_id              = yandex_vpc_network.project.id
  cluster_ipv4_ranges     = ["10.96.0.0/16"]
  service_ipv4_range      = "10.112.0.0/16"
  service_account_id      = yandex_iam_service_account.kubernetes.id
  node_service_account_id = yandex_iam_service_account.nodes.id

  master {
    version = var.kubernetes_version

    zonal {
      zone      = var.zone
      subnet_id = yandex_vpc_subnet.project.id
    }

    public_ip = true

    security_group_ids = [
      yandex_vpc_security_group.cluster_nodegroup_traffic.id,
      yandex_vpc_security_group.cluster_api.id
    ]
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.kubernetes_editor,
    yandex_resourcemanager_folder_iam_member.kubernetes_vpc_public_admin
  ]
}

resource "yandex_kubernetes_node_group" "project" {
  cluster_id = yandex_kubernetes_cluster.project.id
  name       = "${var.project_name}-workers"
  version    = var.kubernetes_version

  instance_template {
    platform_id = var.node_platform_id

    resources {
      cores  = var.node_cores
      memory = var.node_memory_gb
    }

    boot_disk {
      type = "network-ssd"
      size = 64
    }

    network_interface {
      subnet_ids = [yandex_vpc_subnet.project.id]
      nat        = true

      security_group_ids = [
        yandex_vpc_security_group.cluster_nodegroup_traffic.id,
        yandex_vpc_security_group.nodegroup_traffic.id,
        yandex_vpc_security_group.services_access.id
      ]
    }

    scheduling_policy {
      preemptible = true
    }
  }

  scale_policy {
    fixed_scale {
      size = var.node_count
    }
  }

  allocation_policy {
    location {
      zone = var.zone
    }
  }
}
