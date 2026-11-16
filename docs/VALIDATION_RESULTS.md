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
| Trivy image scan | **PASSED** | Trivy 0.76.2 completed against the remediated image: 0 unsuppressed HIGH/CRITICAL OS findings and 0 unsuppressed HIGH/CRITICAL Python findings. The scan initially found patched zlib, Starlette, and setuptools issues; dependencies and OS packages were updated. One exact CVE is documented in `.trivyignore` because Trivy reports a deleted base layer with no `PkgPath`; direct final-filesystem inspection found only fixed setuptools 84.2.1. |
| Kind cluster and smoke tests | **NOT RUN** | Kind was not installed locally. No local cluster deployment result is claimed. |
| GitHub Actions | **PENDING RE-RUN** | Earlier runs stopped in `Set up job` before checkout or project commands. The workflows were simplified to avoid third-party setup actions and duplicate branch runs; the next PR run must provide the authoritative GitHub result. |

No cloud infrastructure was created, no image was published, no credentials were used, and no paid service was invoked.

