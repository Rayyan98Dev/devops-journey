# Mon 16 Nov 2026: root key deleted, Project 2 account decided, CLI login to the lab account

Week 7 of 12 (AWS + Terraform, Project 2).

## Done today

- Deleted the (already deactivated) root access key on my own AWS account.
- Decided where Project 2 runs: my brother's new AWS account on the **Free plan**.
- Free plan confirmed: 182 days (to 16 May 2027), USD 120 credits (100 at sign-up + 20 from the Budgets activity), no card requested.
- MFA on the sign-in identity, two budgets created.
- Created IAM user `learning` (AdministratorAccess). In this account type it has no console sign-in and no MFA section, and it has no credentials.
- CLI login to the lab account works: `aws login --profile lab`, Region `eu-north-1`.
- `aws sts get-caller-identity --profile lab` → `assumed-role/AccountFullAccessRole/...`

## Decision: which account for Project 2

| Option | What happens past the free allowances / credits | Verdict |
|---|---|---|
| My own account (created before Jul 2025, legacy free tier) | Billed to my card, which has no funds behind it | No |
| Brother's account, **Free plan** | No charges possible until someone upgrades the account | **Chosen** |
| Brother's account, Paid plan | Billed to his card beyond the credits | Not applicable (it's on Free) |
| Local only | No cost, but the project is meant to be AWS infrastructure | No |

Reason: on the Free plan a mistake costs credits, not money. Conditions: never click Upgrade; his Google account (the sign-in identity) needs 2-Step Verification.

## Teach-back (my answers, corrected)

1. **Delete, not deactivate, the root key:** an inactive key can be switched back on by anyone who gets into root; a deleted key is gone. Root should have no access keys at all.
2. **Free vs Paid plan:** Free doesn't charge until the account is upgraded; Paid bills anything beyond the credits.
3. **IAM user vs role:** a user is a long-lived identity for one person (password and/or keys). A role has no password or keys of its own; an approved actor assumes it and gets a **session** that expires on its own, like a key card handed out for a limited time. The role stays; the session expires. Permissions come only from attached policies; neither is "limited" by definition. `user/...` in an ARN = a user; `assumed-role/...` = a role session.
4. **Why no access keys:** `aws login` credentials expire by themselves; an access key works until it is **deleted**, so a leaked key does far more harm.
5. **Why the Google account's 2-Step Verification matters:** it's the front door. Anyone who gets into it gets into the AWS account and can do things like click Upgrade, which turns a no-charge account into one that can bill.
6. **No `--profile`:** the CLI uses the `default` profile (my own account) unless `AWS_PROFILE` is set. It never asks or guesses.

## Predictions

- `get-caller-identity --profile lab` prints "my brother's account": half right. It was his account, but I didn't say which identity. It was a role session, not root and not `learning`.
- With no `--profile` it would ask which profile to use: wrong. It used `default` and failed because that login session had expired.

## Project 2 plan (to confirm Tue 09:00)

Serverless visit counter in `eu-north-1`: Lambda + function URL, DynamoDB, least-privilege execution role; Terraform state in S3 with `use_lockfile = true`; GitHub Actions via OIDC (plan on PR, apply on merge); tags, budget, destroy at the end.

Build runs **Tue 17 to Sat 21 Nov** (Saturday added so it can be done calmly).
- Must-have: state backend, Lambda/DynamoDB, least privilege, plan on PR.
- Stretch: apply on merge through OIDC.
- Biggest unknown: whether GitHub OIDC works in this new account type.

## Still open

- Brother turns on Google 2-Step Verification (tonight); sign out of his Google account on my laptop.
- Keep or delete the `learning` user.
- Project 1 README; German A2 week 1 revision.
