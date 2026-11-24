# Tue 24 Nov 2026: README defence + Kubernetes 1 (kind, first pod)

**Done =** defend every line of the Project 2 README; a kind cluster running on the laptop, and I can explain cluster / node / pod and run, inspect and delete a pod.
**Block:** 07:38–12:10 (started 40 min late; README 08:05–09:05 by voice, Kubernetes 09:27–11:50). German moved to the afternoon.

## Recall quiz (Week 7 corrections): 1 ✓, 5 partly, 2 ✗

Still weak: the bootstrap destroy (2nd miss), the three permission checks (1 of 3), the four OIDC steps (forgot). All three came right in the README interview an hour later.
New: versions aren't decimals (6.9 < 6.73); `~>` lets only the **last number written** grow, so `~> 6.73.0` = 6.73.x only.

## README defence (voice, interview style)

Solid now: why provisioned DynamoDB, versioning, what's real vs simulated in A+ ("everything except who presses the button"), the four OIDC steps and why step 2 is by hand (CI can't create its own way in), laptop recovery, the bootstrap destroy (fails half-way, bucket left **less protected**, not orphaned; `lifecycle { prevent_destroy = true }`), `NONE` + reserved **concurrent** executions.
Corrected: function URL vs API Gateway is about **simplicity**, not abuse control (API Gateway is better at that); KMS adds **control** (key policy, audit log, switch-off), not more encryption; `ReadOnlyAccess` can read **every bucket**, and any accepted run gets it.
Found: the README says the plan goes into the PR, but it was pasted once. Parked: fix the wording later, paste full masked plans from now on.

## Kubernetes 1

### One-line models
- **Cluster:** machines run as one; I declare what I want, it keeps reality matching (Terraform's idea, but always running).
- **Control plane:** the brain, a *role*: API server (the only door), etcd (desired state), scheduler, controller-manager. In kind it runs **as pods on the one node**.
- **Node:** a machine that runs pods. In kind, a Docker container (`lab-control-plane`), Debian files on my Fedora kernel.
- **Pod:** smallest thing Kubernetes runs: one or more containers sharing an IP and storage.
- **kubectl:** client; talks only to the API server (HTTPS + certificate in `~/.kube/config`), never to Docker, so no `sudo`.

### What I built
- `kubectl v1.37.2` and `kind v0.33.0` into `~/.local/bin`, both `sha256sum --check` → `OK`.
- `sudo "$(command -v kind)" create cluster --name lab` → node image `kindest/node:v1.37.0`, API server on `127.0.0.1:<random>->6443` (laptop only). Cost about 0.6 GB RAM.
- Kubeconfig copied to `~/.kube/config`, owned by me, `600`. It holds the admin certificate and key: never paste, never commit.
- First pod with `kubectl run`, then by hand in `~/dev/lab/k8s/pod.yaml`.

### What I saw
| Thing | Where it showed |
|---|---|
| 9 system pods before I made any | `kubectl get pods -A` (`kube-system`, `local-path-storage`) |
| Pod scheduling story | `describe` Events: Scheduled → Pulling → Pulled → Created → Started |
| Pod container not in Docker | `docker ps` = only the node; `docker exec lab-control-plane crictl ps` = my pod (containerd) |
| Two networks | node `172.18.0.2` (Docker), pods `10.244.0.x` (CNI, kindnet) |
| Pod IP from laptop | timed out; from inside the node: works |
| `port-forward pod/web 8080:80` | listens on `127.0.0.1`; nginx logged the request from `127.0.0.1` (tunnelled into the pod) |
| `apply` twice | `pod/web unchanged` (like Terraform's "No changes") |
| `nginx -s stop` inside the pod | same pod, same IP, `RESTARTS 1`: the kubelet restarted the container |
| `kubectl delete pod` | gone for good: a bare pod has no controller |

Building picture: node = street address, pods = internal extensions; the laptop is outside, `port-forward` (or a Service) is the receptionist.

### Two kinds of manifest errors
- `error parsing pod.yaml: ... yaml: line N` → **kubectl on the laptop**: broken YAML (indentation, dashes). Nothing sent.
- `Error from server (BadRequest): ... unknown field` → **API server**: wrong field names, listed together.
- Neither catches a wrong *value* (`name: web` instead of `app: web`).

## Scores

| Round | Result |
|---|---|
| Recall quiz | 1 ✓, 5 partly, 2 ✗ |
| R1 install predictions | 0 ✓, 2 partly, 1 ✗ |
| R2 first cluster | 0 ✓, 3 partly, 3 ✗ (2 caught myself) |
| R3 first pod | 0 ✓, 1 partly, 4 ✗ |
| R4 `pod.yaml` | 3 ✓, 1 partly |
| Teach-back | 1 ✓, 2 partly, 2 ✗ |

Repeat slips: control plane "separate" (twice), and thinking `sudo` problems are about credentials. The real rule: my shell does `$(...)` and `>` **before** sudo runs; sudo changes `PATH` and the user, not keys.

## Next

- Wed 25 Nov: Kubernetes 2: Deployments (what brings a deleted pod back), ReplicaSets, labels and selectors, scaling, rolling update + rollback. Cluster `lab` stays up.
- Recall Wed: control plane location, container restart vs pod recreation, `sudo "$(command -v kind)"`, the two error sources.
