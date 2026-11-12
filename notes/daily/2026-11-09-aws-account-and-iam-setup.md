# 2026-11-09 and 2026-11-10: AWS account audit, hardening, IAM user and CLI login

Week 6. Goal: an AWS account safe enough to learn Terraform on, without spending money.

## My account (Mon 9 Nov)

- It is a **legacy pay-as-you-go account** (created before July 2025). There is no Free plan and no credits, so anything billable costs real money.
- The plan: create **no billable resources**, and set a budget alert as a safety net.
- Billable traps: EC2 instances, a NAT gateway, public IPv4 addresses. A resource can be cheap and still bill every hour it exists.
- **Budgets only alert.** They do not stop services. I assumed they did, and that was wrong. Deleting resources is my job.
- Other clouds I looked at: GCP ($300 for 90 days), Azure ($200 for 30 days), Oracle (risky). The choice for Project 2 is still open (decide by Mon 16 Nov).

## Root, IAM user, role

- **Root user:** the email that created the account. It can do everything, including closing the account. Use it for almost nothing.
- **IAM user:** a named identity inside the account with only the permissions it is given. Mine is `Learning`.
- **Role:** an identity that is assumed temporarily, with no password or long-lived keys of its own.
- **Root hardening:** turn on MFA (authenticator app) on root, and have no root access keys. My old root key was about 4 years old. I **deactivated** it, signed out, and will **delete** it on Mon 16 Nov. Deactivate = switched off and reversible; delete = gone for good. Deactivating first proves nothing still depends on it.

## IAM user and CLI (Tue 10 Nov)

- Created the IAM user `Learning` as the admin I use day to day, with MFA on it too.
- Installed the AWS CLI (`aws --version`). Checked who I am with `aws sts get-caller-identity`, which printed my account number and the `Learning` user.
- Logged in with `aws login` instead of a long-lived access key:
  - It gives **15-minute credentials** that refresh automatically for up to **12 hours**, then I log in again.
  - They are cached in `~/.aws/login/cache`. `aws logout` clears them.
  - `~/.aws/config` holds `login_session` (the user's ARN) and `region = eu-central-1`.
- I got the lifetimes wrong at first: the credentials last 15 minutes and refresh, not 12 hours flat.
- Availability Zone **names** (like `eu-central-1a`) are mapped differently per account, so the zone **IDs** are what stay the same across accounts.

## Security thinking

- What a thief gets by copying `~/.aws`: the account number and the cached temporary credentials (short-lived), not a permanent key. That is the point of `aws login`. A static access key in that folder would be valid until someone revokes it.
- Closing a standalone account needs the root user. The "Close account" button looked clickable to my IAM admin; I did not click it (parking lot).

## Teach-back (answered Thu 12 Nov, graded)

- **Root vs IAM user vs role:** root is the email-and-password identity that can do everything, including closing the account and billing. An IAM user is a named identity inside the account with only the permissions it was given. A **role** is **not** "the root and the IAM users" (my answer was wrong): it is an identity that is *assumed temporarily*, with no password or long-lived keys of its own. Services and people take it on when they need it.
- **Why a budget is not a safety net:** it only warns. It does not stop services, and the resources keep running and billing until I delete them.
- **Deactivate vs delete a key:** deactivating stops the key working but is reversible; deleting is permanent. We deactivate first so that if something turns out to depend on it, I can reactivate it.
- **`aws login`:** it gives 15-minute credentials that refresh automatically for up to 12 hours; then I log in again.
