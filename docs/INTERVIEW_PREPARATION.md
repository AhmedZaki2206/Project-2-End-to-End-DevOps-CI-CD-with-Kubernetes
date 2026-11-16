# Interview Preparation

الإجابات دي تصف المشروع كـ personal portfolio/lab، مش production experience. احفظ الفكرة، مش النص. كل سؤال فيه `Short answer` للمراجعة، شرح عربي، و`Sample English Answer` تستخدمه في المقابلة.

## Project pitch في 60 ثانية

**بالعربي:** المشروع عبارة عن FastAPI service بسيطة عملت لها end-to-end delivery path. التطبيق فيه health وversion endpoints وstructured JSON logging واختبارات pytest. بنيت multi-stage Docker image بتشتغل non-root ومع healthcheck. على Pull Requests، GitHub Actions تشغل tests، تبني الصورة، تعمل Trivy scan، وتراجع Kubernetes manifests وHelm chart. بعد merge يدوي على `main`، pipeline تنشر immutable SHA-tagged image على GHCR، لكنها لا تعمل deploy تلقائي. محليًا بعمل Kind cluster، وبنشر Helm release فيه 2 replicas وClusterIP Service وConfigMap وprobes وresources وsecurity contexts، وأقدر أعمل rolling update وrollback. الهدف كان أتدرب على workflow واقعي وآمن، مش ادّعاء production deployment.

**Sample English Answer:** “I built a personal end-to-end DevOps portfolio project around a small FastAPI service. It has health and version endpoints, structured JSON logs, and pytest coverage. I package it in a multi-stage, non-root Docker image. Pull requests run tests, build and scan the image with Trivy, and validate Kubernetes and Helm resources. After a manual merge to main, GitHub Actions publishes an immutable SHA-tagged image to GHCR, but it never deploys automatically. For local deployment I use a two-node Kind cluster and Helm with two replicas, probes, resource controls, and hardened security contexts. The project is a learning environment, not a production claim.”

## Project pitch في 5 دقائق

**Sample English Answer:**

“The project starts with a deliberately small FastAPI application so the delivery platform remains the focus. The application exposes root, liveness, readiness, and version endpoints. Readiness can be controlled by an environment variable, and middleware writes one JSON record per request to stdout with a request ID, status, and duration. Six pytest tests cover the endpoints, the not-ready response, and log formatting, with a 90 percent coverage threshold.

The Dockerfile is multi-stage. The builder creates a virtual environment and installs pinned runtime dependencies. The runtime stage receives only that environment and the application code. It creates UID and GID 10001, runs Uvicorn as that non-root identity, and includes a healthcheck that uses Python rather than adding curl. In Kubernetes, I add defense in depth: a read-only root filesystem, a writable emptyDir only for /tmp, no privilege escalation, all Linux capabilities dropped, RuntimeDefault seccomp, and no service-account token.

For pull requests, GitHub Actions installs Python dependencies, runs pytest, builds the image with the commit SHA as the application version, scans it with a pinned Trivy container, lints and renders the Helm chart, and validates both raw and rendered manifests with Kubeconform. The workflow has read-only repository permission and does not deploy. On main, the essential validation repeats, then the workflow uses the short-lived GITHUB_TOKEN with packages write permission to publish a `sha-<full commit>` image to GHCR. There is intentionally no mutable latest tag.

For local Kubernetes, Kind creates a control-plane and worker node. The deployment path loads the local image into Kind and uses `helm upgrade --install`. The release has two replicas, a ClusterIP service, ConfigMap values, requests and limits, HTTP liveness and readiness probes, and a rolling strategy with zero unavailable and one surge Pod. Scripts and Make targets make build, deployment, status, logs, smoke tests, rollback, and cleanup reproducible.

I can demonstrate failure handling by setting readiness false, using a missing image, reading events and previous logs, and rolling Helm back to a known revision. I also documented limitations: Kind is local, there is no ingress or TLS, no secrets, no autoscaling, and no production observability. The main learning outcome is understanding each transition from source to image, CI, registry, Kubernetes objects, and Helm release rather than treating the pipeline as a black box.”

## 40 Junior DevOps Q&A

### 1. المشروع ده بيحل إيه؟

**Short answer:** بيعرض delivery lifecycle كامل لتطبيق صغير من source لحد local Kubernetes.

**التفصيل:** التركيز على automation وsecurity وdebugging: tests، image، CI، registry، manifests وHelm. هو lab مش production system.

**Sample English Answer:** “It demonstrates a complete and explainable delivery lifecycle for a small API, from source tests and containerization to CI, GHCR publishing, and a manual local Kubernetes deployment.”

### 2. ليه اخترت FastAPI؟

**Short answer:** بسيطة وسريعة وتسمح بالتركيز على DevOps.

**التفصيل:** فيها endpoints واضحة للprobes وversion، وTestClient يسهل الاختبار. المشروع لا يدّعي تصميم backend معقد.

**Sample English Answer:** “I chose FastAPI because it gives me a small, testable HTTP service, so I can focus the project on delivery, containers, CI, and Kubernetes.”

### 3. إيه الفرق بين liveness وreadiness؟

**Short answer:** liveness تعني process سليم؛ readiness تعني يقدر يستقبل traffic.

**التفصيل:** `/health/live` دائمًا 200 أثناء عمل التطبيق. `/health/ready` يرجع 503 لو `APP_READY=false`. kubelet يعيد تشغيل container عند liveness failure، لكنه يخرجه من Service endpoints عند readiness failure.

**Sample English Answer:** “Liveness decides whether Kubernetes should restart the container. Readiness decides whether the Pod should receive Service traffic. This app exposes separate endpoints for those decisions.”

### 4. ليه عندك `/version`؟

**Short answer:** للتأكد أي build شغال.

**التفصيل:** Docker build يضبط `APP_VERSION`، وHelm يضبطها من image tag. ده مفيد بعد rollout أو rollback.

**Sample English Answer:** “The version endpoint makes deployment verification simple because I can confirm which image tag or commit is serving traffic.”

### 5. Structured logging فائدته إيه؟

**Short answer:** logs قابلة للبحث والتحليل آليًا.

**التفصيل:** كل request ينتج JSON على stdout فيه timestamp، request ID، method، path، status وduration. مفيش log files داخل container.

**Sample English Answer:** “JSON stdout logs are easier for container platforms and log collectors to parse, filter, and correlate than free-form local files.”

### 6. إزاي بتعمل correlation للrequests؟

**Short answer:** `x-request-id`.

**التفصيل:** middleware يحافظ على header المرسل أو يولد UUID، يضيفه للresponse والlog.

**Sample English Answer:** “The middleware accepts or generates an `x-request-id`, returns it to the client, and includes it in the structured request log.”

### 7. الاختبارات بتغطي إيه؟

**Short answer:** endpoints، not-ready behavior وJSON formatter.

**التفصيل:** `tests/test_app.py` فيه 6 tests، و`pyproject.toml` يفرض 90% coverage. العدد والنتيجة لازم يتأكدوا من run حقيقي.

**Sample English Answer:** “The current test suite covers all four endpoints, the 503 readiness path, response request IDs, and JSON log formatting.”

### 8. ليه multi-stage Docker build؟

**Short answer:** نفصل build tooling عن runtime.

**التفصيل:** builder يثبت dependencies في venv؛ runtime يأخذ venv والكود فقط. ده يقلل surface area، رغم إن المرحلتين مبنيتان على نفس slim base.

**Sample English Answer:** “A multi-stage build keeps installation work in the builder and copies only the prepared virtual environment and application into the runtime image.”

### 9. ليه container non-root؟

**Short answer:** يقلل أثر الاختراق.

**التفصيل:** Docker user وKubernetes runAsUser هما 10001. التطبيق لا يحتاج privileged port أو root filesystem writes.

**Sample English Answer:** “The process runs as UID and GID 10001, which limits what an attacker could do if the application were compromised.”

### 10. Docker healthcheck بيعمل إيه؟

**Short answer:** يطلب `/health/live` دوريًا.

**التفصيل:** يستخدم `urllib.request` من Python؛ مفيش curl مضاف للصورة. Docker health لا يوجه Kubernetes؛ Kubernetes عنده probes منفصلة.

**Sample English Answer:** “The image healthcheck calls the liveness endpoint with Python’s standard library. Kubernetes still uses its own explicit HTTP probes.”

### 11. ليه `PYTHONUNBUFFERED=1`؟

**Short answer:** logs تظهر فورًا.

**التفصيل:** مهم في containers عشان stdout مايتأخرش في buffer.

**Sample English Answer:** “It prevents log buffering so request logs appear immediately in Docker and Kubernetes logs.”

### 12. CI بيشتغل إمتى؟

**Short answer:** PR workflow على Pull Requests، وpublish workflow على push إلى main.

**التفصيل:** merge يدوي هو اللي يحفز main workflow. لا يوجد automatic deploy.

**Sample English Answer:** “Validation runs on pull requests. A separate workflow validates and publishes only after a commit reaches main.”

### 13. ليه CI مابيعملش deploy؟

**Short answer:** الفصل مقصود للأمان والتعلّم.

**التفصيل:** مفيش cluster credentials في GitHub، والdeployment المحلي خطوة explicit. ده يمنع تغييرات بيئة تلقائية.

**Sample English Answer:** “CI is intentionally read-only toward Kubernetes. It validates artifacts, while local deployment remains an explicit manual action with no cluster credentials stored in GitHub.”

### 14. إيه صلاحيات GitHub Actions؟

**Short answer:** PR `contents: read`؛ main يضيف `packages: write`.

**التفصيل:** ده least privilege للcheckout والنشر على GHCR. `GITHUB_TOKEN` مؤقت، مش PAT مخزن.

**Sample English Answer:** “The PR workflow only reads repository contents. The main workflow adds packages write solely to publish to GHCR with the short-lived GITHUB_TOKEN.”

### 15. ليه SHA image tags؟

**Short answer:** traceability وimmutability.

**التفصيل:** tag مثل `sha-<full commit>` يربط الصورة بكود محدد. المشروع لا ينشر `latest`.

**Sample English Answer:** “A full commit SHA makes the artifact traceable and avoids ambiguity from a mutable latest tag.”

### 16. Trivy بيعمل إيه؟

**Short answer:** يفحص image vulnerabilities.

**التفصيل:** CI يستخدم image version 0.76.2 ويفشل على fixed HIGH/CRITICAL findings مع `--ignore-unfixed`. فيه exception واحدة موثقة لنسخة `setuptools` محذوفة من base layer؛ الـ final filesystem فيه النسخة الآمنة 84.2.1. هو control واحد، مش security guarantee كاملة.

**Sample English Answer:** “Trivy scans the built image and fails CI for high or critical vulnerabilities that have fixes available.”

### 17. Helm lint وtemplate الفرق؟

**Short answer:** lint يراجع chart؛ template يرندر YAML.

**التفصيل:** `helm lint --strict` يكتشف chart issues. `helm template` يطبق values محليًا بدون cluster، وبعدها Kubeconform يراجع الناتج.

**Sample English Answer:** “Lint checks chart structure and conventions, while template renders the final manifests so another validator can inspect the actual YAML.”

### 18. Kubeconform دوره إيه؟

**Short answer:** schema validation للـ Kubernetes YAML.

**التفصيل:** يفحص `k8s` والـ rendered Helm output مع strict mode. `ignore-missing-schemas` يسمح بموارد بلا schema، رغم إن الموارد الحالية core types.

**Sample English Answer:** “Kubeconform validates raw and Helm-rendered Kubernetes resources against schemas before any deployment.”

### 19. Kind هو إيه؟

**Short answer:** Kubernetes nodes داخل Docker containers.

**التفصيل:** المشروع ينشئ control-plane وworker. مناسب للتعلم والCI المحلي، مش production.

**Sample English Answer:** “Kind runs Kubernetes nodes as Docker containers. I use it for a reproducible local two-node learning cluster, not as a production platform.”

### 20. ليه `kind load docker-image`؟

**Short answer:** ينقل local image إلى Kind nodes.

**التفصيل:** nodes لها container runtime منفصل عن host image store. مع `IfNotPresent` تقدر تشغل الصورة بدون registry push.

**Sample English Answer:** “Kind nodes cannot automatically see the host image store, so I load the local image into the cluster before deployment.”

### 21. Namespace فائدته إيه؟

**Short answer:** logical isolation وتنظيم.

**التفصيل:** كل موارد التطبيق في `cloud-native-demo`. Namespace مش security boundary كامل بدون RBAC/NetworkPolicy.

**Sample English Answer:** “The namespace groups the demo resources and scopes commands, although it is not a complete security boundary by itself.”

### 22. Deployment بيضمن إيه؟

**Short answer:** desired replicas وrolling updates.

**التفصيل:** يحافظ على 2 Pods، ينشئ ReplicaSets، ويدير rollout/history.

**Sample English Answer:** “The Deployment reconciles two desired replicas and manages ReplicaSets, rolling updates, and revision history.”

### 23. Service نوعه إيه وليه؟

**Short answer:** ClusterIP للوصول الداخلي فقط.

**التفصيل:** port 80 يوجه للnamed container port `http` وهو 8000. الوصول الخارجي للديمو يتم بـ port-forward.

**Sample English Answer:** “I use a ClusterIP Service because the demo does not need public exposure. It maps port 80 to the Pods’ named HTTP port 8000.”

### 24. ConfigMap بيخزن إيه؟

**Short answer:** non-secret config.

**التفصيل:** `LOG_LEVEL` و`APP_READY`. لا يصح نخزن passwords فيه لأنه ليس encrypted secret storage.

**Sample English Answer:** “The ConfigMap holds non-sensitive runtime settings such as log level and readiness state. I would never place credentials there.”

### 25. requests وlimits الفرق؟

**Short answer:** request للscheduling؛ limit للحد الأعلى.

**التفصيل:** المشروع يطلب 50m CPU/64Mi ويحد 250m/256Mi. الأرقام للديمو ومحتاجة قياس في production.

**Sample English Answer:** “Requests influence scheduling and reserved capacity, while limits cap consumption. These values are learning defaults, not production sizing.”

### 26. RollingUpdate settings معناها إيه؟

**Short answer:** صفر unavailable وواحد surge.

**التفصيل:** controller يحاول يحافظ على كل replicas available، ويمكنه إنشاء Pod إضافية أثناء التحديث. ده يحتاج capacity إضافية.

**Sample English Answer:** “With maxUnavailable zero and maxSurge one, Kubernetes keeps the desired Pods available while temporarily adding one extra Pod.”

### 27. `readOnlyRootFilesystem` فايدته إيه؟

**Short answer:** يمنع الكتابة على image filesystem.

**التفصيل:** يقلل persistence/tampering. `/tmp` مركب كـ `emptyDir` writable لأن بعض runtime operations تحتاج temp space.

**Sample English Answer:** “The container root filesystem is read-only, with only an ephemeral emptyDir mounted at `/tmp` for necessary temporary writes.”

### 28. ليه بتعمل drop لكل capabilities؟

**Short answer:** التطبيق لا يحتاج Linux privileges إضافية.

**التفصيل:** HTTP على 8000 لا يحتاج `NET_BIND_SERVICE`. تقليل capabilities دفاع إضافي.

**Sample English Answer:** “The API needs no special Linux capabilities, so dropping all of them reduces the attack surface.”

### 29. `automountServiceAccountToken: false` ليه؟

**Short answer:** التطبيق لا يحتاج Kubernetes API.

**التفصيل:** يمنع token من الوجود داخل Pod لو التطبيق اتخترق.

**Sample English Answer:** “The application never calls the Kubernetes API, so I disable service-account token mounting to remove unnecessary credentials.”

### 30. seccomp `RuntimeDefault` بيعمل إيه؟

**Short answer:** يطبق default syscall filter.

**التفصيل:** يمنع مجموعة syscalls خطرة. compatibility لازم تتختبر لأي workload مختلف.

**Sample English Answer:** “RuntimeDefault applies the container runtime’s standard syscall filter as an additional defense-in-depth control.”

### 31. تعمل debug لـ CrashLoopBackOff إزاي؟

**Short answer:** describe، current logs، previous logs، config/resources.

**التفصيل:** ابدأ بـ `kubectl describe pod` وEvents، ثم `kubectl logs --previous`. افحص command، exit code، env، permissions وOOMKilled.

**Sample English Answer:** “I inspect the Pod and events, read current and previous container logs, then verify the command, environment, permissions, and whether memory limits caused termination.”

### 32. تعمل debug لـ ImagePullBackOff إزاي؟

**Short answer:** راجع image name/tag، events، registry auth أو Kind load.

**التفصيل:** في المشروع المحلي غالبًا الصورة لم تُحمّل للcluster أو tag غلط. في GHCR private image قد تحتاج imagePullSecret، لكنه غير مطبق هنا.

**Sample English Answer:** “I read the pull event, verify repository and tag, and for this local setup confirm that the image was loaded into the correct Kind cluster.”

### 33. تعمل debug لـ Pending Pod إزاي؟

**Short answer:** scheduler events وnode capacity/taints.

**التفصيل:** `kubectl describe pod` يوضح insufficient CPU/memory، taints، affinity أو unbound volumes.

**Sample English Answer:** “I start with scheduler events, then compare requests with node capacity and check taints, selectors, affinity, and volume binding.”

### 34. Failed readiness probe تصلحه إزاي؟

**Short answer:** تحقق من path/port، app logs وdependencies/config.

**التفصيل:** هنا افحص `APP_READY` في ConfigMap، endpoint من port-forward، وPod events. لا تحذف probe لإخفاء المشكلة.

**Sample English Answer:** “I verify the configured path and port, test the endpoint, inspect logs and events, and check the APP_READY configuration instead of disabling the probe.”

### 35. Rollback بيتم إزاي؟

**Short answer:** Helm history ثم rollback لrevision معروفة.

**التفصيل:** `make rollback REVISION=N` ينفذ `helm rollback --wait` ثم rollout status. بعدها smoke test وversion check.

**Sample English Answer:** “I inspect Helm history, roll back to a known good revision with wait enabled, and then validate rollout status and application endpoints.”

### 36. الفرق بين raw manifests وHelm هنا؟

**Short answer:** raw للتعلم/validation؛ Helm هو deployment path.

**التفصيل:** ملفات `k8s/` ثابتة. chart configurable ويُستخدم في `scripts/deploy.sh`. لازم تتجنب إدارة نفس resource بالاثنين في نفس الوقت.

**Sample English Answer:** “Raw manifests document the base resources and are statically validated, while the configurable Helm chart is the actual deployment path.”

### 37. إزاي تعمل scale؟

**Short answer:** kubectl مؤقتًا أو Helm value بشكل declarative.

**التفصيل:** `kubectl scale` مفيد للتجربة لكن Helm upgrade قد يرجع القيمة. الأفضل تعديل `replicaCount` في release values.

**Sample English Answer:** “I can scale imperatively for a quick test, but for a Helm-managed release I persist the desired replica count through Helm values.”

### 38. إيه limitations المشروع؟

**Short answer:** local only ومفيش production networking/observability/scaling.

**التفصيل:** لا Ingress/TLS/NetworkPolicy/HPA/PDB/persistence/secrets/monitoring. Kind مش production، والreadiness لا يفحص external dependency.

**Sample English Answer:** “The project is intentionally local and learning-focused. It lacks ingress, TLS, network policies, autoscaling, disruption budgets, persistence, and production observability.”

### 39. إيه verified وإيه مش verified؟

**Short answer:** ارجع لـ `docs/VALIDATION_RESULTS.md` والـ current PR checks.

**التفصيل:** ما تقولش check نجح بناءً على وجود workflow. فرّق بين local run، GitHub run، وNOT RUN مثل Kind لو الأداة غير متاحة وقت التسجيل.

**Sample English Answer:** “I separate implemented controls from executed evidence. I report local results and GitHub checks independently and mark anything unavailable as not run.”

### 40. لو هتطوره بعد كده تعمل إيه؟

**Short answer:** supply-chain pinning، integration tests، ingress/TLS وpolicy controls بالتدريج.

**التفصيل:** ممكن pin Actions بالcommit SHA، يضاف SBOM/signing، NetworkPolicy وPDB وHPA بعد قياس، وregistry-based Kind deployment test. دي أفكار future وليست features حالية.

**Sample English Answer:** “Next I would strengthen supply-chain pinning, add an integration test using the published image, and introduce ingress, TLS, network policy, and availability controls only with clear requirements and validation.”

## طريقة التدريب

1. نفّذ كل command في `HANDS_ON_LABS.md` بدل الحفظ النظري.
2. اشرح diagram من source إلى Pod في دقيقتين من غير قراءة.
3. اعمل failure واحد، اجمع evidence، أصلحه، ثم اشرح root cause بالإنجليزي.
4. استخدم صياغة صادقة: “I implemented in a personal lab” بدل “I ran this in production”.
5. لو مش عارف إجابة، قل assumptions ثم اشرح خطوات التحقيق بدل التخمين.

