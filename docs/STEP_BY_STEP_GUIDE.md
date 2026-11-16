# دليل التنفيذ خطوة بخطوة من Windows نظيف

الدليل ده مبني على أوامر وملفات المشروع الفعلية. نفّذ أوامر Linux من Ubuntu داخل WSL2، وسيب Docker Desktop شغال على Windows.

## 1. تجهيز Windows وWSL2

### الهدف

إننا نوفر Linux shell متوافق مع Bash scripts والـ Makefile الموجودين في المشروع، مع Docker Engine من Docker Desktop.

### التثبيت

افتح PowerShell كـ Administrator:

```powershell
wsl --install -d Ubuntu
wsl --update
```

اعمل restart لو Windows طلب، وافتح Ubuntu واختار username/password. بعد كده:

```bash
sudo apt update
sudo apt install -y git make curl ca-certificates python3 python3-venv python3-pip
```

نزّل Docker Desktop من موقع Docker، فعّل `Use the WSL 2 based engine`، ومن `Settings > Resources > WSL Integration` فعّل Ubuntu.

### Validation

```bash
wsl --status
git --version
make --version
python3 --version
docker version
docker run --rm hello-world
```

المتوقع: Docker يعرض Client وServer، و`hello-world` يطبع رسالة نجاح. لو ظهر `Cannot connect to the Docker daemon` شغّل Docker Desktop وراجع WSL Integration.

## 2. تثبيت kubectl وKind وHelm

### kubectl

```bash
KUBECTL_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl kubectl.sha256
```

### Kind

```bash
KIND_VERSION=v0.25.0
curl -Lo kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
chmod +x kind
sudo mv kind /usr/local/bin/kind
```

### Helm

المشروع والـ CI يستخدموا Helm 3.16.3:

```bash
curl -fsSLo /tmp/helm.tar.gz https://get.helm.sh/helm-v3.16.3-linux-amd64.tar.gz
tar -xzf /tmp/helm.tar.gz -C /tmp
sudo install /tmp/linux-amd64/helm /usr/local/bin/helm
```

### Validation

```bash
kubectl version --client
kind version
helm version --short
```

لو architecture جهازك ARM64 غيّر `amd64` إلى `arm64` في روابط الأدوات.

## 3. Clone والفرع

### الهدف

ننزّل نفس repository ونشتغل من Linux filesystem عشان أداء Docker وfile watching يكون أفضل.

```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/AhmedZaki2206/Project-2-End-to-End-DevOps-CI-CD-with-Kubernetes.git
cd Project-2-End-to-End-DevOps-CI-CD-with-Kubernetes
git fetch --all --prune
git switch feature/devops-kubernetes-platform
git status
```

لو الفرع مش موجود محليًا:

```bash
git switch --track origin/feature/devops-kubernetes-platform
```

المتوقع `working tree clean`. ما تحطش tokens أو `.env` في Git؛ `.gitignore` بيستبعد الملفات الشائعة دي.

## 4. فهم الملفات قبل التشغيل

| Path | وظيفته |
|---|---|
| `app/main.py` | FastAPI endpoints، readiness flag، JSON middleware logging |
| `tests/test_app.py` | 6 tests للـ endpoints و503 behavior والـ formatter |
| `requirements.txt` | runtime dependencies: FastAPI وUvicorn |
| `requirements-dev.txt` | pytest/httpx/coverage بالإضافة للـ runtime dependencies |
| `pyproject.toml` | pytest strict mode و90% coverage minimum |
| `Dockerfile` | builder/runtime stages، non-root user، healthcheck |
| `kind-config.yaml` | local two-node cluster |
| `k8s/` | raw manifests للتعلم والvalidation |
| `helm/cloud-native-api/` | chart المستخدم في النشر الفعلي |
| `scripts/` | automation صغيرة وآمنة مع `set -Eeuo pipefail` |
| `Makefile` | واجهة مختصرة للسكربتات |
| `.github/workflows/ci.yml` | PR validation فقط |
| `.github/workflows/publish.yml` | main validation وGHCR publish |

## 5. تشغيل التطبيق محليًا بـ Python

### الهدف

نعزل مشكلة التطبيق عن Docker وKubernetes.

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements-dev.txt
pytest
uvicorn app.main:app --host 127.0.0.1 --port 8000
```

من terminal تاني:

```bash
curl -i http://127.0.0.1:8000/
curl -i http://127.0.0.1:8000/health/live
curl -i http://127.0.0.1:8000/health/ready
curl -i http://127.0.0.1:8000/version
```

المتوقع HTTP 200، وstdout فيه JSON line باسم message `request_completed`. للتأكد من failure readiness:

```bash
APP_READY=false uvicorn app.main:app --host 127.0.0.1 --port 8001
curl -i http://127.0.0.1:8001/health/ready
```

المتوقع `503` و`{"status":"not-ready"}`. لو pytest فشل، اقرأ أول traceback وتأكد إن الـ virtual environment active وإن dependencies اتثبتت من `requirements-dev.txt`.

## 6. Build وتشغيل Docker

### Build

```bash
make build IMAGE_TAG=demo-1
```

ده يستدعي `scripts/build.sh` ويبني:

```text
cloud-native-cicd-kubernetes:demo-1
```

ويتسجل `APP_VERSION=demo-1` داخل الصورة عن طريق build argument.

### Run وvalidation

```bash
docker run --rm --name cloud-native-api -p 8000:8000 \
  --read-only --tmpfs /tmp \
  cloud-native-cicd-kubernetes:demo-1
```

من terminal تاني:

```bash
curl http://127.0.0.1:8000/version
docker inspect --format '{{.Config.User}}' cloud-native-cicd-kubernetes:demo-1
docker inspect --format '{{json .State.Health}}' cloud-native-api
docker logs cloud-native-api
```

المتوقع version `demo-1`، والـ user `10001:10001`، وبعد start period الحالة تبقى `healthy`. لو port 8000 مستخدم غيّر host side مثل `-p 8001:8000`.

## 7. إنشاء Kind cluster

```bash
make cluster-up
kubectl cluster-info --context kind-cloud-native-dev
kubectl get nodes -o wide
```

`scripts/cluster-up.sh` لا يعيد إنشاء cluster لو موجود. `kind-config.yaml` ينشئ control-plane وworker. المتوقع nodeين `Ready` بعد فترة قصيرة.

لو الإنشاء وقف، راجع:

```bash
docker ps
kind export logs /tmp/kind-logs --name cloud-native-dev
```

## 8. النشر اليدوي باستخدام Helm

### الهدف

نحمّل local image إلى nodes وبعدين نعمل install/upgrade للchart. CI لا ينفذ الخطوة دي.

```bash
make build IMAGE_TAG=demo-1
make deploy IMAGE_TAG=demo-1
```

السكربت يعمل بالترتيب:

1. يتأكد إن الأدوات موجودة.
2. يبني الصورة لو غير موجودة.
3. `kind load docker-image` حتى nodes تلاقي local image.
4. `helm upgrade --install` في namespace `cloud-native-demo`.
5. ينتظر rollout لمدة 120 ثانية.

### Validation

```bash
make status
helm list -n cloud-native-demo
helm get values cloud-native -n cloud-native-demo
kubectl get all -n cloud-native-demo
kubectl describe deployment cloud-native-cloud-native-api -n cloud-native-demo
make smoke
```

المتوقع Deployment ready `2/2`، وPodين Running، وService ClusterIP. `make smoke` يعمل port-forward مؤقت ويطلب الأربع endpoints.

## 9. Logs وdebugging

```bash
make logs
kubectl logs -n cloud-native-demo deployment/cloud-native-cloud-native-api --all-pods=true --tail=100
kubectl get events -n cloud-native-demo --sort-by=.metadata.creationTimestamp
kubectl describe pod -n cloud-native-demo <pod-name>
```

- `CrashLoopBackOff`: شوف `kubectl logs --previous`، command، env، permissions والmemory.
- `ImagePullBackOff`: تأكد إن `IMAGE_TAG` اتبنى واتعمله `kind load`، وإن `imagePullPolicy=IfNotPresent`.
- `Pending`: راجع Events وresources وnode readiness.
- readiness fail: اطلب endpoint من داخل Pod أو اعمل port-forward، وراجع `APP_READY` في ConfigMap.
- liveness fail: راجع إن app سامع على port 8000 وإن path صحيح.

## 10. Scale وrolling update

Helm هو source of desired configuration. للتجربة المؤقتة:

```bash
kubectl scale deployment/cloud-native-cloud-native-api -n cloud-native-demo --replicas=3
kubectl get pods -n cloud-native-demo -w
```

لكن أي `helm upgrade` لاحق يرجّع العدد لقيمة `replicaCount`. التغيير الدائم للديمو:

```bash
helm upgrade cloud-native ./helm/cloud-native-api \
  -n cloud-native-demo \
  --reuse-values \
  --set replicaCount=3
```

لبناء release جديد:

```bash
make build IMAGE_TAG=demo-2
make deploy IMAGE_TAG=demo-2
kubectl rollout status deployment/cloud-native-cloud-native-api -n cloud-native-demo
curl http://127.0.0.1:18080/version
```

شغّل `make smoke` بدل آخر curl لو مفيش port-forward مفتوح.

## 11. Rollback

```bash
helm history cloud-native -n cloud-native-demo
make rollback REVISION=1
helm history cloud-native -n cloud-native-demo
make smoke
```

`scripts/rollback.sh` يرفض التشغيل بدون revision، يعرض history، وبعد rollback ينتظر rollout. اختار revision فعلية من history؛ ماتحفظش الرقم بشكل افتراضي.

## 12. GitHub Actions وGHCR

على Pull Request، راقب تبويب Checks. الـ workflow لازم يوصل لخطوات pytest/build/scan/Helm/Kubeconform. لو فشل `Set up job` قبل checkout، المشكلة repository/organization Actions policy أو runner availability، مش tests المشروع.

بعد review وmerge يدوي على `main`، `publish.yml` ينشر SHA tag. لمعرفة الـ SHA:

```bash
git rev-parse HEAD
```

مثال pull بعد نجاح publish:

```bash
docker login ghcr.io
docker pull ghcr.io/ahmedzaki2206/project-2-end-to-end-devops-ci-cd-with-kubernetes:sha-<full-sha>
```

لو package private، استخدم GitHub PAT فيه `read:packages` محليًا. الـ workflow نفسه يستخدم `GITHUB_TOKEN` ومافيش secret يدوي في repository.

## 13. إعادة البناء من الصفر

الأوامر دي تمسح الـ local Kind cluster الخاص بالمشروع فقط، ثم تعيد كل حاجة:

```bash
make clean
docker image rm cloud-native-cicd-kubernetes:local 2>/dev/null || true
rm -rf .venv
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
make test
make build
make cluster-up
make deploy
make status
make smoke
```

`make clean` يستدعي `kind delete cluster --name cloud-native-dev`. هو لا يمسح Git history أو Docker Desktop أو clusters تانية.

## 14. Cleanup

```bash
make clean
docker image rm cloud-native-cicd-kubernetes:local
deactivate
rm -rf .venv
```

لو عايز تمسح release فقط وتسيب cluster:

```bash
helm uninstall cloud-native -n cloud-native-demo
kubectl delete namespace cloud-native-demo
```

قبل demo حقيقي، نفّذ الأوامر بنفسك وسجّل النتائج الفعلية؛ ما تعتمدش على screenshots أو نتائج قديمة.

