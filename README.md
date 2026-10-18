# Podinfo — CI/CD в Yandex Cloud

Проект демонстрирует CI/CD приложения на Go: проверку кода, сборку Docker-образа, публикацию артефактов и развёртывание в Yandex Managed Kubernetes.

## Архитектура и структура

- GitHub и GitHub Actions — исходный код и автоматизация.
- GHCR — хранение версионированных Docker-образов.
- Terraform — инфраструктура Yandex Cloud.
- Managed Kubernetes — запуск приложения.
- Helm — публикация и обновление приложения.
- Prometheus и Grafana — метрики и дашборды.
- Loki и Alloy — сбор и просмотр логов.

Основные каталоги:

- `charts/podinfo/` — Helm chart.
- `infra/terraform/` — IaC и конфигурация backend.
- `deploy/monitoring/` — конфигурации мониторинга и дашборд.
- `otel/` — локальное OTEL-окружение.
- `.github/workflows/` — CI/CD workflows.
- `Dockerfile` — сборка контейнера.

## CI/CD и артефакты

- `test.yml` — проверки кода и конфигураций.
- `project-ci.yml` — тесты Go, проверка Helm, сборка и публикация образа.
- `cve-scan.yml` — проверка уязвимостей.
- `e2e.yml` — E2E-тесты.
- `deploy-yandex.yml` — деплой в Yandex Cloud.

Образы публикуются в `ghcr.io/maksimvgu/podinfo`. Тег вида `sha-abcdef0` позволяет связать артефакт с конкретным коммитом.

Workflow проверок запускаются по событиям, указанным в файлах `.github/workflows/`. `Deploy to Yandex Cloud` запускается при push в `master` или вручную через GitHub Actions. Он использует GitHub OIDC/Workload Identity Federation и Helm.

## Terraform и инфраструктура

Terraform описывает сеть, IAM, Container Registry, Managed Kubernetes и security groups в Yandex Cloud.

Удалённое состояние Terraform хранится в Yandex Object Storage через S3-совместимый endpoint `https://storage.yandexcloud.net`. Имя существующего bucket и ключ state задаются в локальном `infra/terraform/backend.hcl`; они зависят от окружения и не фиксируются здесь.

Локальный `infra/terraform/backend.hcl` содержит параметры подключения и не должен попадать в Git. Используй `backend.hcl.example` как шаблон. Учётные данные передаются через переменные окружения, не сохраняются в репозитории.

Перед изменением инфраструктуры выполни `terraform init`, `terraform fmt -check`, `terraform validate` и `terraform plan`. Изучи план до применения. Не подтверждай неожиданное удаление или замену кластера и node group.

## Развёртывание приложения

Основной способ — GitHub Actions workflow `Deploy to Yandex Cloud`. Он использует Helm chart `charts/podinfo/`, параметры `charts/podinfo/values-yandex.yaml` и образы GHCR с тегом, связанным с SHA коммита.

Проверка приложения: `kubectl get deployments,services,pods -n podinfo`.

Получить актуальный IP сервиса: `kubectl get svc podinfo -n podinfo -o wide`.

Проверка завершения обновления: `kubectl rollout status deployment/podinfo -n podinfo`.

Перед ручным обновлением убедись, что соответствующий образ опубликован в GHCR. Детали команды деплоя находятся в `.github/workflows/deploy-yandex.yml`.

## Мониторинг и логирование

Prometheus собирает метрики, Grafana предоставляет дашборды, Loki хранит логи, Alloy отправляет логи приложения в Loki.

Проверка компонентов: `kubectl get pods -n monitoring` и `kubectl get pods -n loki`.

Применить конфигурацию мониторинга:

```bash
kubectl apply -k deploy/monitoring
```

Деплой приложения через Helm не применяет эти ресурсы автоматически.

### Установка мониторинга на новом кластере

Перед установкой настрой `kubectl` на нужный кластер и проверь наличие StorageClass `yc-network-hdd`.

Добавь Helm-репозитории:

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana-community https://grafana-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update

Создай namespaces:

    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace loki --dry-run=client -o yaml | kubectl apply -f -

До установки Grafana создай Secret `grafana-admin`. Команды ниже запрашивают пароль без отображения на экране и не записывают его в Git.

    set -o pipefail
    umask 077
    secret_dir="$(mktemp -d)"
    printf "Grafana username: "
    IFS= read -r GF_USER
    printf "Grafana password: "
    IFS= read -r -s GF_PASS; printf "\\n"
    printf "%s" "$GF_USER" > "$secret_dir/admin-user"
    printf "%s" "$GF_PASS" > "$secret_dir/admin-password"
    kubectl create secret generic grafana-admin -n monitoring --from-file=admin-user="$secret_dir/admin-user" --from-file=admin-password="$secret_dir/admin-password" --dry-run=client -o yaml | kubectl apply -f -
    result=$?
    rm -rf "$secret_dir"
    unset GF_USER GF_PASS
    test "$result" -eq 0

Установи Helm-релизы с версиями чартов, используемыми проектом:

    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --version 92.10.1 -n monitoring -f deploy/monitoring/kube-prometheus-stack-small-values.yaml
    helm upgrade --install loki grafana-community/loki --version 18.17.1 -n loki -f deploy/monitoring/loki-values.yaml
    helm upgrade --install alloy grafana/alloy --version 1.13.1 -n monitoring -f deploy/monitoring/alloy-values.yaml

Примени datasource Loki, дашборд и ServiceMonitor:

    kubectl apply -k deploy/monitoring

Проверь состояние компонентов:

    kubectl get pods -n monitoring
    kubectl get pods -n loki
    kubectl get servicemonitor podinfo -n monitoring

Эти команды предназначены для первоначальной установки. На существующем кластере не меняй учётные данные Grafana без необходимости.

Для доступа к Grafana выполни `kubectl port-forward -n monitoring svc/prometheus-grafana 3002:80` и открой `http://127.0.0.1:3002`. Учётные данные находятся в Kubernetes Secret `grafana-admin`.

Дашборд проекта: `deploy/monitoring/dashboards/podinfo.json`.

## Релиз, откат и безопасность

История Helm-релизов проверяется командой `helm history podinfo -n podinfo`. Откат выполняется командой `helm rollback podinfo <REVISION> -n podinfo --wait --timeout 5m`, где `<REVISION>` — номер проверенной рабочей ревизии.

Не добавляй в Git пароли, токены, статические ключи, `backend.hcl` или Terraform state. Изменения сетевых правил необходимо проверять на соответствие требуемому доступу к Kubernetes API и сервисам. После изменений проверяй состояние workload, метрики и логи.
