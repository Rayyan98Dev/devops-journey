# Wed 25 Nov 2026: Kubernetes 2 (Deployments, ReplicaSets, labels and selectors, scaling)

Week 8, day 3. First study day on the **desktop** (CachyOS, fish). Started late (errand, then a power cut); Kubernetes 2 ran about 11:00–12:50, wrap-up after.

**Done =** a 3-replica nginx Deployment that heals itself and scales, and I can explain Deployment → ReplicaSet → Pod.
Result: done, except rolling update + rollback (moved to the start of Thu).

## Recall quiz (09:25–09:45)

5 ✓ first time, 3 fixed on rework. Weak: control-plane components (named only etcd), kubelet vs controller, OIDC token flow, `import` records (doesn't create).

## One-line models

- **Deployment:** "I want N copies of this pod, at this version." I write it; it makes and manages ReplicaSets.
- **ReplicaSet:** keeps exactly N pods matching its selector alive. One per **version of the pod template**.
- **Pod from a template:** made by the ReplicaSet, which is its owner (`ownerReferences`). A **bare pod** has no owner.
- **Label:** a name tag on an object (`app: web`). **Selector:** a query over those tags. Controllers find their pods by selector, not by name.
- **Manifest:** describes one object *inside* a cluster and never names the cluster. kubectl's `current-context` decides which cluster.
- **Who fixes what:** container dies → **kubelet** restarts it in the same pod. Pod dies → **ReplicaSet** (in the controller-manager) makes a new pod. Nodes plus a control plane make the cluster.
- **Control plane:** kube-apiserver (only door), etcd (desired state), kube-scheduler (picks a node for a new pod), kube-controller-manager (runs the controllers).

| Docker / Compose | Terraform | Kubernetes |
|---|---|---|
| `deploy.replicas: 3` | `count = 3` | `replicas: 3` |
| the service definition | the resource block | `spec.template` (pod blueprint) |
| — | drift fixed only at the next `apply` | the ReplicaSet checks all the time |

## Desktop cluster (step E)

- Kernel check first: `uname -r` = `7.3.5-2-cachyos`, which is in `/usr/lib/modules` (yesterday's Docker bug was a running kernel with no module folder).
- `sudo "$(command -v kind)" create cluster --name lab` → `kindest/node:v1.37.0`, API server on `127.0.0.1:<port>->6443`. Separate from the laptop's `lab`: each machine has its own Docker and its own `~/.kube/config`.
- `~/.kube/config` didn't exist until `sudo kind get kubeconfig ... > ~/.kube/config` (my shell does the `>`, so I own it). `-rw-------`, owner `catto`, context `kind-lab`.
- Cost: used RAM 2.9 → 3.8 GiB (about 0.9 GB of 31).
- `~/Dev/lab` had broken directory modes (`lab` `rw-`, `terraform` `--x`), not root ownership. Fixed with `chmod -R u+rwX,go+rX,go-w`. See the bug journal.

## The bare-pod gap

`kubectl apply -f pod.yaml`, then `kubectl get pod web -o jsonpath='{.metadata.ownerReferences}{"\n"}'` → empty line (no owner). `kubectl delete pod web` → `No resources found`. Nothing comes back.

## deployment.yaml (hand-written)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: nginx:stable-alpine
          ports:
          - containerPort: 80
```

First draft kept `apiVersion: v1`, `kind: Pod` and a `cluster: lab` selector → `Error from server ... Pod in version "v1" ... unknown field "spec.replicas", "spec.selector", "spec.template"` (predicted).

## What I saw

| Thing | Where it showed |
|---|---|
| 1 Deployment, 1 ReplicaSet, 3 pods | `kubectl get deploy,rs,pods`: `web`, `web-55fbf6bc44`, `web-55fbf6bc44-48v27` ... |
| Name parts | Deployment name + template hash (from the **whole** pod template) + 5 random characters |
| Ownership chain | pod → `ReplicaSet/web-55fbf6bc44` → `Deployment/web` (`ownerReferences`) |
| Extra label | `pod-template-hash=55fbf6bc44`, added by the Deployment. ReplicaSet `SELECTOR` = `app=web,pod-template-hash=55fbf6bc44`, so old and new versions never claim each other's pods |
| Delete an owned pod | new pod `s5h84`, new IP `.8` → `.9`, `RESTARTS 0`, young `AGE` |
| Remove `app` from a pod (`kubectl label pod ... app-`) | that pod is released (empty `ownerReferences`, bare, still running); the ReplicaSet makes `7k4px` to get back to 3 |
| `kubectl scale deployment web --replicas=5` | writes the **Deployment's** `replicas`; same ReplicaSet and hash, `DESIRED 5` |
| `kubectl apply -f deployment.yaml` after scaling | `configured`, back to 3, the two newest removed: drift fixed from the file |

## Three error gates

1. **kubectl parses the YAML:** `error parsing ... line N`. Nothing sent.
2. **kubectl looks up the type** (apiVersion + kind): `no matches for kind "Deployment" in version "v1"`. Nothing sent. kubectl's own typos (`unknown shorthand flag`, `unknown command`) are local too.
3. **The API server checks fields and some values:** `Error from server ... unknown field ...` (all at once), selector vs template labels.

## Teach-back (wrap-up)

1. Control plane: **partly**. etcd ✓, the API server ✓. "kubectrl" was meant to be the controller-manager, but it's the controller-manager that *replaces pods*; the kubelet restarts containers. CoreDNS isn't control plane. Scheduler missing (3rd time).
2. Who fixes what: **partly**. Said kubectl again for container restarts (it's the **kubelet**). Owned pod ✓. Un-labelled pod: left out that the ReplicaSet makes a replacement.
3. Deployment / ReplicaSet / Pod: ✓. The hash is how a ReplicaSet tells *its own version's* pods apart.
4. Why kubectl vs the server: ✗. kubectl catches more than syntax: it also checks the **type** exists before sending.
5. Directories: **partly**. `r` = list, `x` = enter ✓. `rw-` without `x` does *not* let me rename (that needs `w` + `x`); `--x` was for everyone, owner included.

## Still to do (moved)

- Rolling update (change the image), `rollout status` / `history` / `undo`: Thu 07:10–07:45. The Deployment `web` is still running on the desktop for it.
- Delete the bare `web-55fbf6bc44-qhg8w` if it's still there.
- Desktop steps C (bootstrap DR test: imports, plan = No changes) and D (root plan = 6 to add). Don't wipe the laptop until C says No changes.
