resource "yandex_vpc_network" "project" {
  name = "${var.project_name}-network"
}

resource "yandex_vpc_subnet" "project" {
  name           = "${var.project_name}-${replace(var.zone, "-", "-")}-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.project.id
  v4_cidr_blocks = ["10.20.0.0/24"]
  route_table_id = null
}
