resource "yandex_vpc_security_group" "cluster_nodegroup_traffic" {
  name        = "${var.project_name}-cluster-nodegroup-traffic"
  description = "Internal traffic between Kubernetes master and nodes"
  network_id  = yandex_vpc_network.project.id

  ingress {
    description       = "Network load balancer health checks"
    protocol          = "TCP"
    from_port         = 0
    to_port           = 65535
    predefined_target = "loadbalancer_healthchecks"
  }

  ingress {
    description       = "Traffic between master and nodes"
    protocol          = "ANY"
    from_port         = 0
    to_port           = 65535
    predefined_target = "self_security_group"
  }

  ingress {
    description    = "Health checks from private cloud networks"
    protocol       = "ICMP"
    v4_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  egress {
    description       = "Traffic between master and nodes"
    protocol          = "ANY"
    from_port         = 0
    to_port           = 65535
    predefined_target = "self_security_group"
  }
}

resource "yandex_vpc_security_group" "nodegroup_traffic" {
  name        = "${var.project_name}-nodegroup-traffic"
  description = "Pod and service traffic and outbound access for worker nodes"
  network_id  = yandex_vpc_network.project.id

  ingress {
    description    = "Traffic between pods and services"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["10.96.0.0/16", "10.112.0.0/16"]
  }

  egress {
    description    = "Outbound access for images and external services"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "cluster_api" {
  name        = "${var.project_name}-cluster-api"
  description = "Restricted access to Kubernetes API"
  network_id  = yandex_vpc_network.project.id

  ingress {
    description    = "Kubernetes API HTTPS"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["72.56.118.32/32", "92.244.246.72/32"]
  }

  ingress {
    description    = "Kubernetes API secure port"
    protocol       = "TCP"
    port           = 6443
    v4_cidr_blocks = ["72.56.118.32/32", "92.244.246.72/32"]
  }

  egress {
    description    = "Outbound traffic required by Kubernetes master"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "services_access" {
  name        = "${var.project_name}-services-access"
  description = "Public access to Kubernetes NodePort services"
  network_id  = yandex_vpc_network.project.id

  ingress {
    description    = "HTTP and other NodePort services"
    protocol       = "TCP"
    from_port      = 30000
    to_port        = 32767
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
