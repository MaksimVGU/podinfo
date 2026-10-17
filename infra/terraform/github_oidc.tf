resource "yandex_iam_service_account" "github_deploy" {
  name        = "${var.project_name}-github-deploy"
  description = "GitHub Actions deployment account authenticated through OIDC"
}

resource "yandex_iam_workload_identity_oidc_federation" "github" {
  name        = "${var.project_name}-github"
  description = "GitHub Actions OIDC federation for the Podinfo repository"
  folder_id   = var.folder_id

  issuer    = "https://token.actions.githubusercontent.com"
  jwks_url  = "https://token.actions.githubusercontent.com/.well-known/jwks"
  audiences = ["https://github.com/MaksimVGU"]
}

resource "yandex_iam_workload_identity_federated_credential" "github_master" {
  service_account_id  = yandex_iam_service_account.github_deploy.id
  federation_id       = yandex_iam_workload_identity_oidc_federation.github.id
  external_subject_id = "repo:MaksimVGU/podinfo:ref:refs/heads/master"
}

output "github_deploy_service_account_id" {
  description = "Service account ID for GitHub Actions OIDC authentication"
  value       = yandex_iam_service_account.github_deploy.id
}
