# 2026-11-20 (Fri) — Week 7, Project 2 day 4

## Done
- Recall quiz
- **Project 2 is live:** `curl` → 1, 2, then 3 after the tags apply
- PR `fix-region`: explicit `provider "aws"` block (region `eu-north-1`, profile `lab`)
- PR `add-oidc`: OIDC provider + CI role behind `enable_github_oidc = false` → plan "No changes"
- PR `add-tags`: `default_tags` (`project`, `owner`, `managed-by`) → apply `4 changed`
- CI Trivy: 0 HIGH/CRITICAL on every file
- Not done: CI role permissions + workflow job (Saturday); local Trivy scan for MEDIUM/LOW (not installed)

## How the apply went
1. `apply tfplan` → role created, table + log group **denied by SCP in eu-central-1**. No provider block, so the default profile's region was used.
2. Added the provider block → plan `7 to add` → PR → merge → apply.
3. **409** concurrent update: the URL resource and the two permissions changed the function at once → URL tainted.
4. Re-plan (URL destroy + create) → `apply -parallelism=1` → `1 added, 1 destroyed` → `curl` 1, 2.

## Lambda logs (cold vs warm)
| | Request 1 | Request 2 |
|---|---|---|
| Init | 470 ms (`INIT_START`) | none |
| Duration | 292 ms | 23 ms |
| Billed | 762 ms (init included) | 24 ms |
| Memory used | 90 of 128 MB | 90 of 128 MB |
All lines are Lambda's own (`START`/`END`/`REPORT`); my code prints nothing yet.

## One-line models
- **Backend vs provider:** `backend` region/profile = where **state** lives. `provider` region/profile = where **resources** are built. Separate settings.
- **Stale plan:** a saved plan belongs to the state it was made from. Any apply (even a failed one) that changes state makes it stale; merging the same code doesn't.
- **`apply tfplan`** never asks `yes`: the reviewed plan is the decision.
- **409 race:** Lambda takes one change per function at a time; `-parallelism=1` makes Terraform go one resource at a time.
- **Tainted:** created but not finished → the next plan replaces it.
- **OIDC:** GitHub signs a short-lived token per run; AWS trusts GitHub's provider; the run swaps it for temporary credentials. Nothing stored.
- **`Service` vs `Federated`:** an AWS service vs an outside identity AWS trusts.
- **`sub` with exact values:** without it, any GitHub repo could take the role; with `:*`, any branch in mine.
- **`count = var.x ? 1 : 0`:** a switch. The resource becomes a list → `[0]`, and anything using `[0]` needs the same `count`.
- **Tags:** in-place updates. `default_tags` = can't forget one; resource tag wins on the same key.
- **Trivy's `0`:** 0 HIGH/CRITICAL, because the table is filtered by the same severity as the gate.

## Wrap-up teach-back
| # | Question | Result |
|---|---|---|
| 1 | Why Frankfurt, and the fix | ✓ |
| 2 | Stale plan, and why twice | ✗ (blamed the URL; it was the state changing after each failed apply) |
| 3 | The 409 and `-parallelism=1` | ✓ (called it 402) |
| 4 | `count` switch and how to reference it | partly (no `[0]`) |
| 5 | Why exact `sub` values | partly |
| 6 | 5 to change vs 4 changed | partly |
| 7 | Cold vs warm start | ✓ |

## Weak spots for Saturday's quiz
- Stale plan: what changes state
- `count` references with `[0]`
- `sub` condition: any repo vs any branch
- Plans can overcount ("read during apply"), never undercount
