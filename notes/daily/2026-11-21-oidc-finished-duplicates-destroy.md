# 2026-11-21 (Sat) — Week 7, Project 2 day 5 (last build day)

## Done
- Recall quiz
- PR `oidc-permissions`: CI role permissions behind the switch → plan "No changes"
- PR `oidc-workflow`: job `terraform-plan-oidc`, shown as **Skipped** on the PR
- PR `remove-duplicate-permissions`: plan `2 to destroy` → apply → `curl` 4 → `get-policy` lists 2 statements
- Destroy rehearsal → decision **destroy** → `6 destroyed`; old URL returns `403`; `state list` empty
- Moved: Project 2 README → Mon 23 Nov 07:30

## Evidence for the README
`curl` returned 1, 2 (Fri), 3 (after tags), 4 (after removing duplicates), 5, 6, 7 (before destroy). Logs: cold start 470 ms init + 292 ms, warm 23 ms.

## OIDC, finished but off
| Piece | What it does |
|---|---|
| `aws_iam_openid_connect_provider.github` | AWS trusts tokens signed by GitHub |
| `github_trust` | only `aud = sts.amazonaws.com` and `sub` = this repo's `main` or a PR |
| `github_ci_state` | `ListBucket`; `GetObject` on the state; Get/Put/Delete on `.tflock` |
| `ReadOnlyAccess` | lets `plan` read every resource (broad: can read data too) |
| job `terraform-plan-oidc` | `id-token: write`, `contents: read`; `configure-aws-credentials` v6.3.0 by SHA |
| Switches | Terraform `count` (`enable_github_oidc = false`) and repo variable `ENABLE_OIDC` |
| Still blocking it | SCP denies `iam:*Provider*`; `profile = "lab"` would fail `init` on a runner |

## One-line models
- **Stale vs drift:** stale = state changed after the plan; drift = real infrastructure changed outside Terraform.
- **`plan` locks too**, so a read-only CI role still needs write on `.tflock`.
- **A named profile never falls back** to `default`.
- **`count` and `[0]`:** every block that indexes `[0]` gets the same `count`.
- **`state list`** = what Terraform manages; the `.tf` files can include things that don't exist.
- **`destroy`** acts in AWS; data goes with the resource; random names (the URL) change on rebuild.
- **Root vs bootstrap destroy:** root can't touch the state bucket; destroying bootstrap would delete the bucket holding root's state.

## Week 7 teach-back
| # | Question | Result |
|---|---|---|
| 1 | Project 2 in three sentences | ✗ (described Project 1) |
| 2 | What's simulated in A+ | partly |
| 3 | Three least-privilege decisions | partly |
| 4 | Why remove the two permissions | ✓ |
| 5 | Bootstrap vs root, and `destroy` | partly |
| 6 | Bring it back for a demo | partly |
| 7 | Hardest thing, and what changes | ✓ (wall cheat sheet) |

## Project 2 in three sentences (corrected)
A serverless visit counter: a Python Lambda behind a public function URL increments a count in DynamoDB, all built with Terraform in AWS `eu-north-1`. State lives in a versioned, encrypted S3 bucket with native locking, and every change goes through a PR where CI runs `fmt`, `validate` and `trivy config`. The account blocks GitHub OIDC, so plans are reviewed in the PR and applied from `main` by hand; the OIDC code is written and switched off.

## Rebuild
```bash
aws login --profile lab
terraform plan -out=tfplan   # 6 to add
terraform apply tfplan       # new URL, count starts at 1
```
