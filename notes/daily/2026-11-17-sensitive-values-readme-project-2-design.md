# Tue 17 Nov 2026: sensitive values, plan without creating, Project 1 README, Project 2 design

Week 7 of 12 (AWS + Terraform, Project 2).

## Done today

- Recall quiz: questions 1, 2 and 5 right (one word fixed in 2); 3 and 4 reworked correctly (the `AWS_PROFILE` environment variable beats `default`; `-var` beats `terraform.tfvars` beats `TF_VAR_name`).
- **Project 2 design agreed** ("A+" workflow, below). Copy: `claude/project-2-design.md`; it goes into the new repo as `docs/design.md` on Wednesday.
- **Terraform catch-up done:** sensitive values (local provider) and plan without creating (AWS provider, `lab` profile, `eu-north-1`, provider v6.73.0 read the `aws login` session directly).
- **Project 1 README merged.** Every command was tested from a clean, isolated clone. PR run: push skipped; merge run: push ran (so the scan had passed).
- Week 7 ClickUp tasks created for Wed to Sat (quiz, build, wrap-up each day).

## Finding: GitHub OIDC is blocked in this account

- `aws iam list-open-id-connect-providers --profile lab` → `AccessDenied ... with an explicit deny in a service control policy`.
- AWS manages guardrail SCPs on new-experience accounts. Its Deny on `iam:*Provider*` also covers `CreateOpenIDConnectProvider`, so GitHub Actions can't log in by OIDC. An explicit Deny above the account beats any Allow inside it, even full access.
- Page to read: AWS Account Management, "Managed policies for your organization" (`scps-and-rcps-for-projects`); look for `DenyIAMRestrictedActions`.

## Decision: Project 2 workflow "A+"

- **Production-grade:** Terraform code, S3 remote state with locking (`use_lockfile = true`), least-privilege IAM, no stored keys, PR review, required checks on `main`.
- **CI on every PR, no AWS login:** `terraform fmt -check`, `init -backend=false`, `validate`, `trivy config`.
- **By hand:** `plan -out=tfplan` locally, plan summary pasted into the PR, `apply tfplan` from `main` after the merge.
- **Written but off:** OIDC provider and CI role behind `enable_github_oidc = false`.
- README says plainly what a pipeline would run and why it's manual here (SCP evidence).
- Build Wed 18 to Sat 21 Nov; Saturday also has German.

## Free-tier facts checked (AWS pages, 17 Nov)

- On the Free plan, Lambda, DynamoDB, S3, IAM, STS, CloudWatch Logs and Budgets are available; no multi-Region features.
- Always free: Lambda 1M requests and 400,000 GB-seconds a month; DynamoDB 25 GB, 25 RCU, 25 WCU. Guides say this covers **provisioned** capacity, not on-demand: build the table `PROVISIONED`, 1/1.
- S3 isn't in the always-free list for this plan: expect cents of credits for the state file.

## Teach-back (my answers, corrected)

1. **SCP:** AWS sets guardrail SCPs on this account type; the Deny on `iam:*Provider*` blocks the OIDC provider; explicit Deny beats Allow, so `AccountFullAccessRole` can't override it.
2. **`sensitive = true`:** a curtain, not a lock. It hides values in plan, apply and the bare `terraform output` list. It doesn't hide a named output, `-raw`, or the state file (clear text, also in `terraform.tfstate.backup` after `destroy`). The lock is who can read the state. Real fix: don't put secrets in Terraform.
3. **`(known after apply)`:** AWS generates the ARN at creation; Terraform only knows what it was given or has read. **Still shaky:** delete the block of a resource that *was applied* and `plan` shows `- ... 1 to destroy`, because the state remembers it. "No changes" is only right when nothing was ever applied.
4. **Compose variables:** `.env` (or the shell) fills in `${...}` inside `compose.yaml`; then `environment:` beats `env_file:` (`app.env`) beats Dockerfile `ENV`. Still shaky: hands-on test in the parking lot.
5. **Fresh-clone test:** a Compose project is named after its folder; my clone's folder had the same name as my real project, so it reused my real Redis and volume. `-p <name>` isolates. Never `down -v` without `-p`.
6. **Project 2 workflow:** see "Decision". Simulated: running `plan`/`apply` by hand, pasting plans, the OIDC role being off. A PR builds but doesn't push so that only reviewed, tested, merged code is published.

## Predictions

- Sensitive output without `sensitive = true`: guessed warning; it's an error.
- `terraform output secret_echo` and `-raw` hidden: no; named output and `-raw` print the value; `grep` found it twice in the state.
- ARN in a plan: guessed my brother's ARN; it's `(known after apply)`.
- Delete a never-applied block: guessed an error; it's `No changes`.
- Missing secret file in a fresh clone: guessed "unhealthy"; the container isn't created at all (`invalid mount config`).
- Fresh clone count: right (1 in an isolated project).
- Skipped the prediction three times (which checks run on a README PR; why a PR doesn't push); answered from the PR's Checks tab instead.

## Open

- README sections 5 and 6 (security decisions, what I learned): second small PR on Wednesday.
- Hands-on test of Compose variable precedence; tomorrow's quiz re-tests Terraform plan-after-delete.
- Keep or delete IAM user `learning`; brother's Google 2-Step Verification.
- Song metadata service idea (after Project 2).
