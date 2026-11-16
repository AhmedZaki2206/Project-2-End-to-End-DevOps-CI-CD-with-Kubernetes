# Validation Results

Execution date: 2026-11-16

Environment: Windows, Python 3.13.9, Docker Desktop 29.1.5, kubectl 1.34.1

| Check | Status | Evidence / explanation |
|---|---|---|
| pytest | **PASSED** | 6 tests passed; 100% statement coverage. One upstream Starlette deprecation warning was reported. |
| Docker build | **PASSED** | `cloud-native-cicd-kubernetes:local` built successfully from the multi-stage Dockerfile. |
| Container runtime | **PASSED** | Container ran as `10001:10001`; Docker health became `healthy`; all four endpoints returned HTTP 200; structured logs were observed. A second run passed with a read-only root filesystem and tmpfs `/tmp`. |
| Helm lint | **PASSED** | Helm 3.16.3: one chart linted, zero failures. The optional icon recommendation is informational. |
| Helm template | **PASSED** | Namespace, ConfigMap, Service, and Deployment rendered successfully. |
| Kubernetes schema validation | **PASSED** | Kubeconform 0.6.7: 7 resources valid, 0 invalid, 0 errors, 0 skipped across raw and Helm-rendered manifests. |
| Bash script syntax | **PASSED** | All 10 scripts passed `bash -n` using the official Bash 5.2 container image. |
| GitHub Actions syntax | **PASSED** | Both workflows passed actionlint 1.7.7 with shellcheck integration. |
| Trivy image scan | **NOT RUN** | Trivy 0.58.1 started, but the 134 MiB vulnerability database did not finish downloading within the available local execution window. No vulnerability pass result is claimed; CI remains configured to run a blocking scan. |
| Kind cluster and smoke tests | **NOT RUN** | Kind was not installed locally. No local cluster deployment result is claimed. |
| GitHub Actions | **FAILED** | Two branch runs stopped in `Set up job` with 0 ms billable runner time before checkout or any project command. Local actionlint passed, so the repository/account Actions policy or runner availability must be corrected by the owner; application checks did not execute on GitHub. |

No cloud infrastructure was created, no image was published, no credentials were used, and no paid service was invoked.

