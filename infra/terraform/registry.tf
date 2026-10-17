resource "yandex_container_registry" "project" {
  name = "${var.project_name}-registry"
}
