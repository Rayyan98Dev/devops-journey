# Thu 26 Nov 2026: Rollouts, Services, ConfigMaps, Secrets

Week 8, day 4. Desktop (CachyOS, fish), kind cluster `lab`, files in `~/dev/lab/k8s`.

**Done =** roll out and roll back an image, put a Service in front of the pods and reach it, feed config and a secret into the pods.
Result: done. Namespaces moved to Mon 30 Nov.

## Recall quiz

1 Partly (CoreDNS listed, scheduler missing a 4th time → mnemonic **ACES**). 2 Mostly ✓. 3 ✓. 4 Partly (gate 2 is kubectl). 5 Partly (`w` only works with `x`). 6 ✗ (described switching OIDC on, not the flow). 7 Partly (`import` does nothing in AWS). 8 Reason ✗ (desired state is in etcd, not kubectl).

## One-line models

- **Rolling update:** new template → new ReplicaSet (new hash), scaled up while the old one scales down. `maxSurge` 25% rounds up (1 extra pod), `maxUnavailable` 25% rounds down (0 missing).
- **Revision:** one per template version, stored on its ReplicaSet. `undo` copies an old template forward as a **new** revision. After an undo, fix the file.
- **`kubectl diff -f`:** what an `apply` would change. Kubernetes' `terraform plan`.
- **Service:** a stable name + virtual IP (Service range `10.96.x`) in front of the pods its selector matches. **EndpointSlice** = the current pod IPs. **kube-proxy** writes the rules inside the node. **CoreDNS** (`10.96.0.10`) turns `web` into the IP.
- **ClusterIP:** inside the cluster only. **NodePort:** also a port 30000–32767 on every node's IP.
- **port-forward:** `127.0.0.1` on my desktop → tunnel → **one** pod.
- **ConfigMap:** settings in etcd, plain text. As env var: read once at container start. As file: re-synced while running.
- **Secret:** like a ConfigMap, base64 (not encryption). Protected by permissions, hidden in `describe`, mounted on **tmpfs**.

## What I saw

| Thing | Where it showed |
|---|---|
| Rollout to `nginx:mainline-alpine` | old ReplicaSet → 0, new one 3/3, kept for rollback |
| Bad tag | new pod `ErrImagePull` / `ImagePullBackOff`, 3 old pods still `Running`, `rollout status --timeout=30s` timed out |
| `rollout undo` | reused the previous ReplicaSet, warning about last-applied config; history `2, 3, 5, 6` |
| `kubectl diff -f` | showed the image going back to the bad tag until I fixed the file; then empty |
| Desktop off overnight | same pods, `RESTARTS 4`: kind came back by itself |
| Service | `ClusterIP 10.96.42.19`; endpoints = the 3 pod IPs; delete a pod → same Service IP, one endpoint `.10` → `.13` |
| From the desktop | `curl 10.96.42.19` timed out |
| From a busybox pod | `nslookup web` → `web.default.svc.cluster.local` = `10.96.42.19` (server `10.96.0.10`); `wget http://web` → nginx page |
| port-forward svc | all 3 requests on one pod, client logged as `127.0.0.1` |
| NodePort 30080 | `127.0.0.1:30080` refused; node IP `172.18.0.2:30080` worked (the desktop is on the Docker network) |
| ConfigMap as files | `ls /usr/share/nginx/html` = `GREETING`, `index.html` (image's files hidden) |
| ConfigMap edit | page changed after ~60 s; `GREETING` didn't; no new ReplicaSet. `rollout restart` → new ReplicaSet → new value |
| Secret | `-o yaml` = `YmFuYW5hLTEyMw==`, `base64 -d` = `banana-123`; `describe` = `10 bytes`; mounted file decoded, on `tmpfs` |
| Secret at `/run/secrets` read-only | `RunContainerError`: collided with the service-account token path → moved to `/etc/web-secret` |
| Shell history | the dummy secret was in fish history, and the delete commands leaked it again |

## Files (hand-written)

`deployment.yaml` now has: image `nginx:mainline-alpine`, env `GREETING` from ConfigMap `web-config`, ConfigMap volume at `/usr/share/nginx/html`, Secret `web-secret` volume read-only at `/etc/web-secret`.
`service.yaml`: `type: NodePort`, `selector: app: web`, `port: 80`, `targetPort: 80`, `nodePort: 30080`.
`configmap.yaml`: `GREETING` and `index.html`. The Secret was made with `kubectl create secret` (dummy value, not in a file).

## Teach-back

1. **Partly.** kubelet restarts containers ✓, ReplicaSet replaces pods ✓. `web` → IP is **CoreDNS**, not the API server (the API server only hands out the Service's IP).
2. **Mostly ✓.** Missed that undo gives the old template a new revision number.
3. **Partly.** IP from the API server's Service range ✓. Didn't explain endpoints, why the desktop can't reach it, or why NodePort on `172.18.0.2` works.
4. **Partly.** File updates live ✓. The env var needs `kubectl rollout restart deployment web` (new pods), not a cluster restart.
5. **✓.** Base64 is trivially decoded, and the value leaked into shell history.
6. **✗.** Gate 2 is **kubectl** (the client), not the kubelet. OIDC 4 steps not answered.

Weak spots for Monday: kubectl vs kubelet (still), CoreDNS = names, scheduler (ACES), OIDC in 4 steps, why Service IPs are unreachable from outside.
