# Junior DevOps Interview Q&A

1. **What does this pipeline do?** It tests a FastAPI app, builds and scans its image, validates Kubernetes/Helm configuration, and publishes an immutable image after a merge to `main`.
2. **Why is deployment absent from CI?** The project separates artifact delivery from an explicit local deployment decision and avoids exposing cluster credentials.
3. **Why use a multi-stage Dockerfile?** Build tooling and caches stay out of the runtime image, reducing size and attack surface.
4. **Why run as non-root?** A compromised process has fewer privileges inside the container.
5. **What is the Docker healthcheck for?** It reports container-level application liveness to Docker; Kubernetes uses separate probes.
6. **Readiness versus liveness?** Readiness removes a Pod from Service endpoints; liveness restarts an unhealthy container.
7. **What does a Deployment provide?** Declarative replica management, self-healing, rollout history, rolling updates, and rollback.
8. **Why use a ClusterIP Service?** It gives stable in-cluster discovery without exposing the lab publicly.
9. **What is a ConfigMap?** A Kubernetes object for non-secret configuration. Secrets must not be stored in it.
10. **Requests versus limits?** Requests influence scheduling and guaranteed capacity; limits cap resource usage.
11. **Why two replicas?** They demonstrate rolling availability and self-healing across more than one Pod.
12. **How is the local image used by Kind?** `kind load docker-image` copies it into cluster nodes, avoiding a registry push.
13. **Why immutable SHA tags?** They identify the exact source revision and avoid ambiguous tag mutation.
14. **How is GHCR authentication handled?** The main workflow uses the short-lived `GITHUB_TOKEN` with only `packages: write` and `contents: read`.
15. **Why can a PR not publish?** Publishing lives in a workflow triggered only by pushes to `main`; PR validation has read-only permissions.
16. **What does Trivy detect here?** Known operating-system and Python dependency vulnerabilities in the built image; HIGH/CRITICAL fixed findings block CI.
17. **What does `helm lint` do?** It checks chart structure and common template mistakes; `helm template` proves rendering with supplied values.
18. **How do you troubleshoot `Pending` Pods?** Inspect events, requests, node capacity, taints, selectors, volumes, and scheduler messages.
19. **How do you roll back?** Inspect `helm history`, run `helm rollback`, and verify Deployment rollout and probes.
20. **Is this production experience?** No. It is a personal portfolio lab demonstrating repeatable DevOps fundamentals and honest validation evidence.

