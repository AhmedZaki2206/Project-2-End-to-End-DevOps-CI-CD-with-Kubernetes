# Hands-on Labs

الـ labs دي معمولة على التنفيذ الفعلي للمشروع. شغّلها من WSL2 داخل repository root. كل lab فيها هدف، تنفيذ، نتيجة متوقعة، validation وtroubleshooting.

## Lab 1: Test الـ FastAPI source

**Goal:** تثبت إن business behavior شغال قبل Docker.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
pytest -v
```

**How it works:** `pyproject.toml` يفرض coverage لا تقل عن 90%. `tests/test_app.py` يختبر الأربع endpoints، readiness 503، وJSON formatter.

**Expected:** ست tests يتم اكتشافهم. النتيجة الدقيقة تعتمد على run الحالي؛ ما تسجلش `PASSED` إلا لو command انتهى بـ exit code 0.

**Troubleshooting:** لو ظهر import error، تأكد إنك في repository root وإن `.venv` active. لو coverage أقل، اقرأ `term-missing` قبل ما تضيف test.

## Lab 2: Readiness failure بدون تغيير الكود

**Goal:** تفهم الفرق بين process شغال وPod ready.

```bash
APP_READY=false APP_VERSION=readiness-lab \
  uvicorn app.main:app --host 127.0.0.1 --port 8000
```

في terminal تاني:

```bash
curl -i http://127.0.0.1:8000/health/live
curl -i http://127.0.0.1:8000/health/ready
curl -i http://127.0.0.1:8000/version
```

**Expected:** liveness `200`, readiness `503`, version `readiness-lab`. ده يثبت إن liveness مش هي نفسها readiness.

## Lab 3: Build وفحص Docker image

**Goal:** تبني multi-stage non-root image وتراجع metadata.

```bash
make build IMAGE_TAG=lab-1
docker image inspect cloud-native-cicd-kubernetes:lab-1
docker inspect --format '{{.Config.User}}' cloud-native-cicd-kubernetes:lab-1
docker history cloud-native-cicd-kubernetes:lab-1
```

**Expected:** user هو `10001:10001`، والـ history يوضح builder output بدون source tests أو dev dependencies.

**Validation:** شغّل container بقيود شبه Kubernetes:

```bash
docker run --rm -d --name api-lab \
  --read-only --tmpfs /tmp \
  --security-opt no-new-privileges \
  -p 8000:8000 cloud-native-cicd-kubernetes:lab-1
sleep 12
docker inspect --format '{{.State.Health.Status}}' api-lab
curl http://127.0.0.1:8000/version
docker stop api-lab
```

**Troubleshooting:** لو الاسم مستخدم نفّذ `docker rm -f api-lab`. لو health لسه `starting`، استنى start period ثم أعد inspect.

## Lab 4: Structured logs وrequest ID

**Goal:** تربط request بالـ JSON log.

```bash
docker run --rm -d --name api-logs -p 8000:8000 cloud-native-cicd-kubernetes:lab-1
curl -i -H 'x-request-id: interview-demo-123' http://127.0.0.1:8000/health/live
docker logs api-logs
docker stop api-logs
```

**Expected:** response header والـ log يحتويان `interview-demo-123`، والlog فيها method/path/status/duration.

## Lab 5: Create Kind cluster

**Goal:** تعمل Kubernetes محلي من Docker containers.

```bash
make cluster-up
kind get clusters
kubectl get nodes -o wide
kubectl config current-context
```

**Expected:** cluster اسمه `cloud-native-dev`، context اسمه `kind-cloud-native-dev`، وnodeين Ready.

**Troubleshooting:** لو node NotReady، انتظر ثم `kubectl describe node <name>`. لو Docker غير شغال، أصلحه قبل Kind.

## Lab 6: Render وراجع Helm قبل deployment

**Goal:** تشوف YAML النهائي بدون تغيير cluster.

```bash
helm lint helm/cloud-native-api --strict
helm template cloud-native helm/cloud-native-api \
  --namespace cloud-native-demo \
  --set namespace.name=cloud-native-demo \
  --set image.tag=lab-1 \
  --set replicaCount=3 > /tmp/rendered.yaml
grep -nE 'replicas:|image:|runAsUser:|readOnlyRootFilesystem:' /tmp/rendered.yaml
```

**Expected:** replicas 3، image tag `lab-1`، UID 10001، read-only filesystem true. `helm template` لا يعمل install.

## Lab 7: Manual Helm deployment

**Goal:** تنشر local image يدويًا؛ مفيش CI deployment.

```bash
make deploy IMAGE_TAG=lab-1
make status
helm status cloud-native -n cloud-native-demo
kubectl get pods -n cloud-native-demo -o wide
```

**Expected:** Deployment `2/2` وPodين Running. لو `ImagePullBackOff`، نفّذ:

```bash
kind load docker-image cloud-native-cicd-kubernetes:lab-1 --name cloud-native-dev
kubectl rollout restart deployment/cloud-native-cloud-native-api -n cloud-native-demo
```

## Lab 8: Service وrequest path

**Goal:** تثبت إن ClusterIP يختار Pods بالlabels.

```bash
kubectl get service cloud-native-cloud-native-api -n cloud-native-demo -o yaml
kubectl get endpointslices -n cloud-native-demo \
  -l kubernetes.io/service-name=cloud-native-cloud-native-api
kubectl port-forward -n cloud-native-demo service/cloud-native-cloud-native-api 18080:80
```

في terminal تاني:

```bash
curl http://127.0.0.1:18080/
curl http://127.0.0.1:18080/version
```

**Expected:** EndpointSlice فيها Pod IPs. لو فاضية، قارن Service selector مع Pod labels.

## Lab 9: Scale

**Goal:** تشوف Deployment controller بيحقق desired state.

```bash
kubectl scale deployment/cloud-native-cloud-native-api \
  -n cloud-native-demo --replicas=4
kubectl get pods -n cloud-native-demo -w
```

بعد ما يبقوا 4:

```bash
kubectl scale deployment/cloud-native-cloud-native-api \
  -n cloud-native-demo --replicas=2
```

**Note:** ده imperative change. الـ Helm value لسه 2؛ أي upgrade يرجع desired config للchart.

## Lab 10: Rolling update

**Goal:** تراقب `maxUnavailable: 0` و`maxSurge: 1`.

```bash
make build IMAGE_TAG=lab-2
kind load docker-image cloud-native-cicd-kubernetes:lab-2 --name cloud-native-dev
helm upgrade cloud-native ./helm/cloud-native-api \
  -n cloud-native-demo --reuse-values --set image.tag=lab-2
kubectl rollout status deployment/cloud-native-cloud-native-api -n cloud-native-demo
kubectl get replicasets -n cloud-native-demo
```

**Validation:** `make smoke` والـ `/version` لازم يرجع `lab-2` لأن chart يضبط `APP_VERSION` من image tag.

## Lab 11: Helm rollback

**Goal:** ترجع revision سابقة بشكل controlled.

```bash
helm history cloud-native -n cloud-native-demo
make rollback REVISION=1
helm history cloud-native -n cloud-native-demo
make smoke
```

اختار revision موجودة بدل `1` لو history مختلف. `make rollback` يعمل wait للrollout. بعده `/version` لازم يعكس tag الموجود في revision المسترجعة.

## Lab 12: Logs

**Goal:** تجمع logs من كل Pods.

```bash
make logs
kubectl logs -n cloud-native-demo \
  deployment/cloud-native-cloud-native-api \
  --all-pods=true --tail=50
```

اعمل requests من terminal تاني وشوف JSON logs. للخروج من follow استخدم `Ctrl+C`.

## Lab 13: Events وPending Pod

**Goal:** تتعلم diagnosis من scheduler Events بدون تعديل دائم للrepository.

```bash
kubectl run impossible-pod -n cloud-native-demo \
  --image=busybox:1.36 --restart=Never \
  --requests='cpu=100' -- sleep 3600
kubectl get pod impossible-pod -n cloud-native-demo
kubectl describe pod impossible-pod -n cloud-native-demo
kubectl get events -n cloud-native-demo --sort-by=.metadata.creationTimestamp
kubectl delete pod impossible-pod -n cloud-native-demo
```

**Expected:** غالبًا Pending لأن 100 CPU أكبر من local nodes. لو scheduler قبله على جهاز بموارد مختلفة، زوّد الطلب مؤقتًا. Event هيشرح `Insufficient cpu`.

## Lab 14: ImagePullBackOff debugging

**Goal:** تخلق failure آمن وبعدين تصلحه بـ rollback.

```bash
helm upgrade cloud-native ./helm/cloud-native-api \
  -n cloud-native-demo --reuse-values \
  --set image.repository=does-not-exist.invalid/cloud-native-api \
  --set image.tag=missing
kubectl get pods -n cloud-native-demo -w
```

بعد ظهور الخطأ:

```bash
kubectl describe pod -n cloud-native-demo <new-pod-name>
kubectl get events -n cloud-native-demo --sort-by=.metadata.creationTimestamp
helm history cloud-native -n cloud-native-demo
helm rollback cloud-native <previous-good-revision> -n cloud-native-demo --wait
```

ما تسيبش release broken؛ نفّذ rollback وتأكد بـ `make smoke`.

## Lab 15: Failed readiness probe

**Goal:** تشوف إن Pod Running لكن مش Ready.

```bash
helm upgrade cloud-native ./helm/cloud-native-api \
  -n cloud-native-demo --reuse-values --set config.appReady=false
kubectl get pods -n cloud-native-demo -w
```

في terminal تاني:

```bash
kubectl describe pod -n cloud-native-demo <new-pod-name>
kubectl logs -n cloud-native-demo <new-pod-name>
```

الـ rollout قد ينتهي timeout لأن `maxUnavailable=0` والـ new Pod مش ready. أصلح:

```bash
helm upgrade cloud-native ./helm/cloud-native-api \
  -n cloud-native-demo --reuse-values --set config.appReady=true --wait
```

## Lab 16: CrashLoopBackOff analysis

**Goal:** تتمرن على logs الحالية والسابقة. اعمل Pod منفصلة، مش Deployment المشروع:

```bash
kubectl run crash-lab -n cloud-native-demo \
  --image=busybox:1.36 --restart=Always -- sh -c 'echo crash-demo; exit 1'
kubectl get pod crash-lab -n cloud-native-demo -w
kubectl logs crash-lab -n cloud-native-demo
kubectl logs crash-lab -n cloud-native-demo --previous
kubectl describe pod crash-lab -n cloud-native-demo
kubectl delete pod crash-lab -n cloud-native-demo
```

**Expected:** restart count يزيد وstatus يبقى CrashLoopBackOff. الفرق: `logs --previous` يجيب آخر terminated container instance.

## Lab 17: PR CI inspection

**Goal:** تربط local checks بالpipeline.

```bash
git switch feature/devops-kubernetes-platform
git status
git log --oneline -5
```

افتح PR Checks وراجع بالترتيب: pytest، build، Trivy، Helm، Kubeconform. لو job فشل في `Set up job` قبل checkout، راجع GitHub Actions permissions/policy. لو Trivy فشل، اقرأ CVE وfixed version؛ ماتستخدمش ignore عشوائي.

## Lab 18: Cleanup كامل

```bash
helm uninstall cloud-native -n cloud-native-demo || true
make clean
docker image rm cloud-native-cicd-kubernetes:lab-1 \
  cloud-native-cicd-kubernetes:lab-2 2>/dev/null || true
```

**Validation:** `kind get clusters` لا يعرض `cloud-native-dev`. التنظيف لا يحذف repository أو Git commits.

