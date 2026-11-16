# Learning Guide

This guide explains the project from a networking professional's perspective. It is a personal lab, not a production platform.

## 1. Git and delivery flow

Git stores versioned snapshots. A feature branch isolates a change; a pull request exposes its diff and runs automated checks before a human chooses whether to merge it. The repository uses two workflows: pull-request validation and a `main` workflow that publishes a container. CI validates and packages; it never deploys to Kubernetes.

**Exercise:** create a branch, change the root API message, run tests, inspect `git diff`, and open a PR. Observe which checks run and why the image is not published from the PR.

## 2. Docker

A Docker image is an immutable filesystem plus metadata. A container is a running process created from that image. This Dockerfile separates dependency installation from the final runtime stage, runs as UID/GID `10001`, exposes only the application port, and includes a healthcheck. Layer ordering improves cache reuse.

```bash
docker build -t cloud-native-cicd-kubernetes:local .
docker run --rm -p 8000:8000 cloud-native-cicd-kubernetes:local
docker inspect --format '{{json .State.Health}}' <container-id>
```

**Exercise:** change a Python file and compare build cache output. Run `docker exec <id> id` and confirm the process is not root.

## 3. CI/CD and GitHub Actions

Continuous Integration runs repeatable tests for every proposed change. Continuous Delivery produces a deployable artifact while retaining a manual deployment decision. On PRs this project runs pytest, builds and scans an image, validates raw YAML, and lints/renders Helm. On `main`, it repeats essential tests and pushes `sha-<commit>` to GHCR. An immutable tag links an image to source history.

The publish job receives only `contents: read` and `packages: write`. Forked/untrusted PRs cannot reach the publish workflow because it triggers only after a push to `main`.

**Exercise:** intentionally break one test and read the failing job. Fix it instead of disabling the check.

## 4. Kubernetes core objects

- **Pod:** the smallest scheduled unit; here it contains one FastAPI container.
- **Deployment:** maintains two Pod replicas and performs rolling updates.
- **Service:** provides stable ClusterIP discovery while Pods are replaced.
- **ConfigMap:** injects non-sensitive runtime configuration.
- **Namespace:** provides a logical boundary for the lab.

Requests influence scheduling; limits cap consumption. Readiness controls whether a Pod receives Service traffic. Liveness asks Kubernetes to restart an unhealthy container. They solve different problems and should not share overly aggressive timings.

**Exercise:** scale to three replicas, watch Pods appear, then delete one Pod and observe reconciliation:

```bash
kubectl -n cloud-native-demo scale deployment/cloud-native-cloud-native-api --replicas=3
kubectl -n cloud-native-demo get pods -w
```

## 5. Helm

Helm combines templates with values. The chart renders the same logical resources as the raw manifests, but deployment uses Helm only—never both at the same time. Values make image repository/tag, replicas, ports, probes, and resources configurable.

```bash
helm lint helm/cloud-native-api --strict
helm template cloud-native helm/cloud-native-api --namespace cloud-native-demo
```

**Exercise:** render with `--set replicaCount=3` and find the changed field without installing it.

## 6. Rolling updates and rollback

The Deployment uses `maxUnavailable: 0` and `maxSurge: 1`: Kubernetes starts a replacement before removing an old ready replica. Helm stores release revisions.

```bash
helm upgrade cloud-native helm/cloud-native-api -n cloud-native-demo --set image.tag=<new-tag>
kubectl -n cloud-native-demo rollout status deployment/cloud-native-cloud-native-api
helm history cloud-native -n cloud-native-demo
make rollback REVISION=1
```

**Exercise:** deploy an invalid image tag, inspect `ImagePullBackOff`, then roll back.

## 7. Practical learning path

1. Run pytest and explain each endpoint.
2. Build/run the image and inspect its user and health.
3. Render and compare raw YAML with Helm output.
4. Create Kind, load the local image, deploy, and run smoke tests.
5. Scale, update, observe, and roll back.
6. Break a probe path and use events/logs to diagnose it.
7. Delete the cluster and recreate the entire environment from Git.

