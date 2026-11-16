# Validation Results

Execution date: 2026-11-16

Environment: Windows, Python 3.13.9, Docker Desktop 29.1.5, kubectl 1.34.1

| Check | Status | Evidence / explanation |
|---|---|---|
| pytest | **PASSED** | Re-run in Python 3.12 Linux container: 6 tests passed; 100% statement coverage. One upstream Starlette deprecation warning was reported. The run first exposed a missing repository import path; `pythonpath = ["."]` was added to `pyproject.toml`, and the identical command then passed. |
| Docker build | **PASSED** | `cloud-native-cicd-kubernetes:docs-validation` built successfully from the multi-stage Dockerfile. |
| Container runtime | **PASSED** | Container ran as `10001:10001`; Docker health became `healthy`; all four endpoints returned HTTP 200; structured logs were observed. A second run passed with a read-only root filesystem and tmpfs `/tmp`. |
| Helm lint | **PASSED** | Re-run with Helm 3.16.3 container: one chart linted, zero failures. The optional icon recommendation is informational. |
| Helm template | **PASSED** | Re-run successfully; ConfigMap, Service, and Deployment rendered with the default values. The Namespace is intentionally omitted when `namespace.create=false`. |
| Kubernetes schema validation | **PASSED** | Re-run with Kubeconform 0.6.7: 4 raw plus 3 Helm-rendered resources valid; 0 invalid, 0 errors, 0 skipped. |
| Bash script syntax | **PASSED** | All 10 scripts passed `bash -n` using the official Bash 5.2 container image. |
| GitHub Actions syntax | **PASSED** | Both updated workflows passed actionlint 1.7.7 with shellcheck integration. |
| Trivy image scan | **NOT RUN** | Trivy 0.58.1 started, but the 134 MiB vulnerability database did not finish downloading within the available local execution window. No vulnerability pass result is claimed; CI remains configured to run a blocking scan. |
| Kind cluster and smoke tests | **NOT RUN** | Kind was not installed locally. No local cluster deployment result is claimed. |
| GitHub Actions | **PENDING RE-RUN** | Earlier runs stopped in `Set up job` before checkout or project commands. The workflows were simplified to avoid third-party setup actions and duplicate branch runs; the next PR run must provide the authoritative GitHub result. |

No cloud infrastructure was created, no image was published, no credentials were used, and no paid service was invoked.

