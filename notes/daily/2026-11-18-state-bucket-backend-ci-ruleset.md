# 2026-11-18 (Wed) — Week 7, Project 2 day 2

Teach-back done Thu 19 Nov morning (moved from Wed).

## Built
- New repo `aws-serverless-visit-counter`; `.gitignore` first
- `bootstrap/` (local state): S3 state bucket with versioning, 4 public-access blocks, SSE-S3, tags
- Root backend: S3 + `use_lockfile = true` + `encrypt = true`
- CI `terraform-checks`: fmt, `init -backend=false` + validate, Trivy config (HIGH/CRITICAL), bootstrap validate; actions pinned by SHA
- Ruleset `protect-main`: PR required, required check, no force push, no deletion — direct push rejected (GH013) as predicted
- PR #1 merged, CI green on `main`

## Teach-back results
| # | Question | Result |
|---|---|---|
| 1 | Why bootstrap has local state, root doesn't | ✓ |
| 2 | Laptop dies: lost / survives / recover | ✓ (after rework) |
| 3 | Label vs `bucket` argument; renaming the label | partly |
| 4 | Why the backend block takes literals only | ✓ (after rework) |
| 5 | What `use_lockfile` does | partly |
| 6 | Why `init -backend=false` in CI | partly |
| 7 | Why pin by SHA, how verified | partly |
| 8 | Why both PR rule and status-check rule | ✓ |
| 9 | Why ignore AWS-0132, and the risk | partly |

## One-line models (the corrected answers)
- **Bootstrap state:** the bucket can't hold the state of the config that creates it → bootstrap keeps state locally; root's backend block sends its state to the bucket. Root's `.terraform/terraform.tfstate` only records *which* backend, no resources.
- **Laptop dies:** lost = bootstrap's `terraform.tfstate` (+ `.terraform/`, `tfplan`). Survives = root state (S3), code (GitHub), bucket (AWS). Recover = 4 `terraform import`: bucket, versioning, public access block, encryption.
- **Label vs `bucket`:** label = Terraform's address (`aws_s3_bucket.state`), never sent to AWS. `bucket` = the real global name. Renaming the label → plan shows **destroy + create**. Fix: a `moved { from = … to = … }` block. Plan *shows* the destroy; it doesn't *stop* it.
- **Backend literals only:** the backend is read *during* `init`, before variables or resources are evaluated.
- **`use_lockfile`:** a `.tflock` object in the S3 bucket next to the state, only while plan/apply runs; S3 conditional writes, no DynamoDB; Terraform ≥ 1.10.
- **`-backend=false`:** CI has no AWS credentials (no access keys; SCP blocks the OIDC provider), so `init` must not contact S3 — it only downloads providers.
- **SHA pinning:** tags can be moved; a 40-char SHA can't. Verified with `git ls-remote <repo> | grep <sha>`; the `# vX.Y.Z` comment must match that action's tag.
- **PR rule + status check:** a direct push has no PR and no check run, so a status check alone can't stop it; the PR rule forces every change through a run.
- **AWS-0132 ignore:** customer-managed KMS ≈ USD 1/month, not worth it for a learning bucket. Risk: the ignore is repo-wide by rule ID, so a *future* bucket is skipped silently. Narrower: `.trivyignore.yaml` with paths.

## Weak spots to revisit
- `moved` blocks (didn't know them)
- *How* I verified SHAs, not just why
- Rule-ID ignores apply to the whole repo
