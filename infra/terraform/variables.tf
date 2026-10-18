variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
}

variable "zone" {
  description = "Availability zone"
  type        = string
  default     = "ru-central1-d"
}

variable "project_name" {
  description = "Project resource name prefix"
  type        = string
  default     = "podinfo"
}

variable "kubernetes_version" {
  description = "Kubernetes minor version"
  type        = string
  default     = "1.35"
}

variable "node_platform_id" {
  description = "Compute platform for Kubernetes worker nodes"
  type        = string
  default     = "standard-v3"
}

variable "node_cores" {
  description = "Worker node vCPU count"
  type        = number
  default     = 2
}

variable "node_memory_gb" {
  description = "Worker node memory in GB"
  type        = number
  default     = 4
}

variable "node_count" {
  description = "Initial number of worker nodes"
  type        = number
  default     = 1
}
