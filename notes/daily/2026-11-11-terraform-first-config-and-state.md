# 2026-11-11 — Terraform: first config, state, plan symbols, drift

Week 6. Local provider only, no cloud, nothing billable. Terraform v1.17.1 (HashiCorp dnf repo, key fingerprint checked against hashicorp.com/security before accepting).

## The four commands

- `terraform init`: downloads the providers the config needs into `.terraform/` and writes `.terraform.lock.hcl`.
- `terraform plan`: compares config, state and reality and shows what *would* change. Changes nothing.
- `terraform apply`: shows the plan, then does it. Only the word `yes` is accepted (I typed `1` once: "Apply cancelled", nothing happened).
- `terraform destroy`: removes what Terraform created from this config. `hello.bar` went; `terraform.tfstate` stayed (now empty of resources) and `terraform.tfstate.backup` appeared.

> Check: `init` also downloads the provider plugin. Terraform's own memory (the state file) is not something `destroy` removes.

## State

- Config (`main.tf`) = what I want. State (`terraform.tfstate`) = what Terraform believes it made. Reality = what is actually there. `plan` compares all three.
- State is plain JSON. My file's `"content": "hello"` was readable in it. So anything Terraform manages, passwords included, sits in the state in the clear. `sensitive = true` only hides values in terminal output.
- Git: **commit** `main.tf` and `.terraform.lock.hcl`. **Ignore** `.terraform/`, `terraform.tfstate`, `terraform.tfstate.backup` (state can hold secrets; `.terraform/` is re-downloadable).

> Check: my first answer ("it tells terraform what it expects to be the terraform folder") was wrong. State records what Terraform created and believes exists; it is not about the folder.

## Reading a plan

| Symbol | Meaning | Last line looks like |
|---|---|---|
| `+` | create | `1 to add, 0 to change, 0 to destroy` |
| `~` | update in place | `0 to add, 1 to change, 0 to destroy` |
| `-/+` | destroy then create (replace) | `1 to add, 0 to change, 1 to destroy` |
| `-` | destroy | `0 to add, 0 to change, 1 to destroy` |

- A replace is spotted by `-/+`, the words "must be replaced", and `# forces replacement` next to the attribute. It counts as one add plus one destroy, never as a change.
- The **provider** decides per attribute whether an edit is in place or a replace. `local_file`: changing `content` forces replacement. `terraform_data`: changing `input` updates in place. Same kind of edit, different result, so read the plan every time.
- Why it matters: on real infrastructure a replace can delete a database and its data, or give a server a new address. A file is only the safe practice version.
- `Note: You didn't use the -out option`: without `-out`, a later `apply` plans again. `-out` saves the exact plan (matters in CI).

> Check: I predicted a replace would show "0 add, 1 change, 0 destroy". Wrong: that is the in-place line.

## Idempotent

Running the same config again changes nothing. My second `apply` said "No changes. Your infrastructure matches the configuration." A bash script that appended a line would add it again every run; Terraform checks first.

## Drift

Drift = reality changed behind Terraform's back. I deleted `hello.bar` by hand: the plan wanted to create it again (`1 to add`). I appended `hacked` to it: `apply` planned a create and rewrote the file, and my edit was gone. The config is the source of truth, so changes are made in the `.tf` files, then plan, then apply.

## Lock file

`.terraform.lock.hcl` records the exact provider version and its hashes, so the next `init` (or CI) gets the same binary and can't be quietly swapped. Same idea as pinning an action by commit SHA or an image by digest.

## Permissions

`local_file` defaults to `0777` (everyone can read, write and execute). Plan showed `file_permission = "0777"`. Fixed with `file_permission = "0600"` and `directory_permission = "0700"`. The least-privilege rule applies to what Terraform creates too.

## `if: always()` (GitHub Actions, from Friday's quiz)

```yaml
jobs:
    simple-job:
        runs-on: ubuntu-latest
        steps:
            - run: pytest

    report:
        needs: simple-job
        if: always()
        runs-on: ubuntu-latest
        steps:
            - run: echo "simple-job ended with ${{ needs.simple-job.result }}"
```

- `needs:` means wait for it. Without `if:`, a failed `simple-job` means `report` is **skipped**.
- With `if: always()`, `report` runs whether `simple-job` passed or failed.
- Right for reporting and clean-up. Wrong for `build-image`: never push an image whose tests failed.
