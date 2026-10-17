resource "yandex_resourcemanager_folder_iam_member" "github_deploy_k8s_viewer" {
  folder_id = var.folder_id
  role      = "k8s.viewer"
  member    = "serviceAccount:${yandex_iam_service_account.github_deploy.id}"
}

resource "yandex_kubernetes_cluster_iam_member" "github_deploy_editor" {
  cluster_id = yandex_kubernetes_cluster.project.id
  role       = "k8s.cluster-api.editor"
  member     = "serviceAccount:${yandex_iam_service_account.github_deploy.id}"
}
