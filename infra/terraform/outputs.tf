output "network_id" {
  value = yandex_vpc_network.project.id
}

output "subnet_id" {
  value = yandex_vpc_subnet.project.id
}

output "registry_id" {
  value = yandex_container_registry.project.id
}

output "cluster_id" {
  value = yandex_kubernetes_cluster.project.id
}

output "cluster_name" {
  value = yandex_kubernetes_cluster.project.name
}
