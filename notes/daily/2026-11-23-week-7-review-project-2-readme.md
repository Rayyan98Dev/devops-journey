# Mon 23 Nov 2026: Week 7 review + Project 2 README

Week 8 day 1 turned into a deep review of Week 7, so Kubernetes starts Tue 24 Nov (one day of slip; Weeks 11–12 are the buffer, kept for polish).

**Done =** I can explain every file in `aws-serverless-visit-counter` without notes, and the README is drafted from my own answers.
**Block:** 08:30–12:00, plus a voice walk-through until about 12:45. Overran: rounds took about twice the planned time.

## The one-line model of the day

Terraform has **three places**, and most of my wrong answers mixed two of them up:

| Place | What it is | Where it lives | Changed by |
|---|---|---|---|
| **Code** | what I *want* | Git (`*.tf`) | me, via PR |
| **State** | what Terraform *remembers* creating | S3 bucket (root), local file (bootstrap) | `apply`, `import`, `destroy` |
| **Real infrastructure** | what *exists* | AWS | `apply`, or someone in the console (= drift) |

- Stale plan = **state** moved since the plan was saved. Drift = **reality** moved. Changed code = just my next change.
- Second pattern: **a description vs the thing itself**: `app.py` vs the running function, a `data` block (writes JSON) vs a `resource` (creates and attaches it), `Table()` (a handle) vs the table.

## Project 2 in three sentences

A public visit counter on AWS: a function URL runs a Python Lambda that adds 1 to a count in DynamoDB and returns it. All infrastructure is Terraform, with state in an S3 bucket (built by a separate bootstrap config) and least-privilege IAM. Changes go through a PR with CI checks (fmt, validate, Trivy); after merge I apply the reviewed saved plan by hand, because the account's SCP blocks GitHub from logging in to AWS.

## Following one request

| Step | What is checked |
|---|---|
| curl → **function URL** (`NONE`) | function's **resource policy**: `InvokeFunctionUrl` + `InvokeFunction` (added by the URL resource itself) |
| Lambda runs `handler` | **reserved concurrency 2** (extra requests throttled) |
| Lambda takes on its role | **trust policy**: only `lambda.amazonaws.com` |
| `UpdateItem` on `visits` | **permissions policy**: that one action on that one table |
| logs | permissions policy: `CreateLogStream`/`PutLogEvents` on `group-arn:*` (every stream in the group) |

Three different checks: who may call the function, who may become the role, what the role may do.

## File by file (what I can now explain)

- **`main.tf`**: not "in charge" of anything. Terraform reads every `.tf` file in the folder as one config (never subfolders, so `bootstrap/` is separate). It holds folder-wide settings: `required_version >= 1.10` (for `use_lockfile`), provider `~> 6.0` (6.x only, < 7.0), `backend` (where **state** lives) and `provider` (where and as whom **resources** are created; Frankfurt on 20 Nov was the missing provider block). `default_tags` go on every taggable resource; a resource's own tag wins on the same key.
- **`bootstrap/main.tf`**: no backend block, so local state. Bucket (real infrastructure that *holds* root's state; `state` is only its label), versioning (restore an old state file after a bad write), public-access block (all `true` = locked), SSE-S3 encryption (AWS-owned key; KMS would add control and an audit trail). References like `aws_s3_bucket.state.id` give one name in one place **and** the creation order.
- **`iam.tf`**: one who (the Lambda service, via the trust policy), two whats (the table and the log group, via the permissions policy). Data blocks write the JSON; `aws_iam_role` and `aws_iam_role_policy` create and attach it. `lambda.tf` links the function to the role with `role = aws_iam_role.lambda.arn`.
- **`lambda.tf`**: `archive_file` zips `src/app.py` locally (no AWS call); `filename` is the zip Terraform uploads; `source_code_hash` spots code changes; `app.handler` = file `app.py`, function `handler`. `TABLE_NAME` env var keeps the name out of the code. `depends_on` is needed because the function doesn't *reference* the log group or the role *policy*. Changing `memory_size` = `~`; changing `function_name` = `-/+`, plus a new URL and lost logs.
- **`src/app.py`**: `Table()` is a handle built once per cold start (470 ms vs 23 ms warm). `ADD` on a missing item creates it with 1.
- **`oidc.tf`**: off twice (Terraform `count` and repo variable `ENABLE_OIDC`). The OIDC provider is AWS saying "I trust GitHub's signature"; GitHub issues the token itself; `client_id_list` is the accepted audience. Only `github_trust` is a trust policy (exact `StringEquals` on `aud` and `sub`: `main` and PRs of my repo). `github_ci_state` (permissions: list the bucket, read state, read/write/delete the lock) + `ReadOnlyAccess` (plan reads real resources; can read every bucket, so too broad).
- **`ci.yml`**: `terraform-checks` on PRs and pushes to `main`, no credentials at all (that's why `init -backend=false`; bootstrap's plain `init` works because its state is local). Every action pinned by full SHA. `terraform-plan-oidc` needs job 1 green and `ENABLE_OIDC == 'true'`; `configure-aws-credentials` is the actual OIDC login (`id-token: write`); `-input=false` so a runner fails instead of waiting for someone to type. Plan only, by design.

## Scores

| Round | Result |
|---|---|
| 1 Recall quiz (Week 7) | 2 ✓, 5 partly, 1 ✗ |
| 2 `bootstrap/` | 2 ✓, 2 partly, 1 ✗ |
| 3 Root config + app | 3 ✓, 4 partly, 3 ✗ |
| 4 OIDC + CI | 1 ✓, 3 partly, 1 ✗ |
| Voice walk-through | all files explained; fixes on `main.tf`, label vs name, the OIDC provider, the missing `configure-aws-credentials` step |

Repeat offenders (now on the cheat sheet): a named profile never falls back to `default` (third time), label vs real name, exact names (`id-token`, `ENABLE_OIDC`).

## Found in the repo

- No `README.md`, and `docs/design.md` is empty (0 bytes). README drafted today.
- The bootstrap CI step is already above Trivy (open question closed).
- No account numbers in the repo; the `grep` hits were lock-file hashes. The account ID is a repository variable.

## Next

- Tue 24 Nov 07:00: recall quiz, 07:10 README review + PR `add-readme` (fill or delete `docs/design.md`), then Kubernetes 1 on the laptop (kind, single node).
- Week 8 tasks created in ClickUp (Tue–Thu Kubernetes 1–3, Fri big review). Week 9 planned on Thursday.
