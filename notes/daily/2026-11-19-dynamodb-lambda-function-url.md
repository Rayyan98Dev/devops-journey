# 2026-11-19 (Thu) — Week 7, Project 2 day 3

## Done
- Wed wrap-up: teach-back, notes PR `notes-2026-11-18` merged
- Project 1 README: "Security decisions" and "What I learned" merged — **Project 1 finished**
- Recall quiz
- Project 2 branch `add-counter`: `dynamodb.tf`, `logs.tf`, `iam.tf`, `lambda.tf`, `src/app.py`
- `plan -out=tfplan` → `Plan: 8 to add, 0 to change, 0 to destroy.` PR open with the plan summary
- Not done: merge, `apply tfplan` from `main`, `curl` → Friday morning

## Decisions
| Decision | Why |
|---|---|
| DynamoDB `PROVISIONED`, 1 RCU / 1 WCU | always-free covers provisioned capacity only (pricing page checked) |
| Function URL public (`NONE`) + reserved concurrency 2 | `curl` and a portfolio demo work; the cap limits a flood. No card on the account, so abuse can only burn credits. Revisit before May 2027 |
| Log group in Terraform, 7 days | auto-created groups never expire; Terraform also deletes it on `destroy` |
| Role allows only `UpdateItem` + its own log stream | code never reads (`GetItem` dropped); Terraform makes the group (`CreateLogGroup` not needed) |
| Python 3.13, 128 MB, 5 s timeout, zip via `archive_file` | small, always-free, no image |

## One-line models
- **Provisioned vs on-demand:** provisioned = book a speed, pay per hour, throttled above it. On-demand = pay per request, no ceiling.
- **Reserved concurrency 2:** at most 2 copies of the function run at once; extra requests are throttled. A cap, not a shield.
- **Account concurrency:** 400 here. You can reserve up to the unreserved amount minus 100.
- **Trust vs permissions:** trust = **who** may take the role (`lambda.amazonaws.com`). Permissions = **what** the role may do, on **which** resources.
- **Two auth settings:** `authorization_type` on the URL = the front door (`NONE` / `AWS_IAM`). `function_url_auth_type` on the permission = a condition that must match it.
- **Two permissions for a public URL** (since Oct 2025): `lambda:InvokeFunctionUrl` (may you use the URL?) and `lambda:InvokeFunction` (may you run the function?). Like a building door and an office door: missing either = 403.
- **`ADD visits :one`:** creates the item and attribute if missing, so the first visit returns 1.
- **Code outside `handler`:** runs once per new copy; later requests reuse it.

## Look-alikes
| | `.terraform.lock.hcl` | `.tflock` |
|---|---|---|
| Locks | provider versions | the state |
| Holds | versions + hashes | who holds the lock |
| Lives | repo (committed) | S3 bucket, only during plan/apply |

## Teach-back results
| # | Question | Result |
|---|---|---|
| 1 | Provisioned vs on-demand | ✓ |
| 2 | What reserved concurrency 2 does / doesn't | ✗ |
| 3 | Trust vs permissions policy | partly (swapped "which resource") |
| 4 | Why create the log group in Terraform | ✓ |
| 5 | Why two permissions for a public URL | ✗ (didn't know) |
| 6 | What the `visit-coutner` typo breaks | partly (Lambda can't create the group) |

## Weak spots to revisit Friday
- Reserved concurrency (cap vs shield)
- Two URL permissions
- Lists, quotes and attributes in HCL (`[...]`, references without quotes, `.json`/`.id`/`.arn`)
