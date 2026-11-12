# 2026-11-12: Terraform variables, locals, outputs, and the AWS provider (read-only)

Week 6. Block 5 in `~/dev/lab/terraform/02-variables` (local provider, nothing billable). Block 6 in `~/dev/lab/terraform/03-aws-read-only` (AWS provider, reads only, nothing created in AWS).

## Block 5: variables, locals, outputs

### init and the lock file

- I copied `.terraform.lock.hcl` into a new folder but not `.terraform/`. `terraform init` printed `Reusing version 2.9.1 of hashicorp/local from the dependency lock file`, then installed that exact version again.
- `main.tf` only gives a **range** (`~> 2.5`). The lock file holds the **exact version** and the hashes, so the same binary is installed everywhere.
- The AWS lock file (Block 6) showed it clearly: `version = "6.73.0"` (what was installed), `constraints = "~> 6.0"` (what `main.tf` allowed), then `hashes`. Commit it. Do not commit `.terraform/` (772 MB there).

> Check: I predicted `init` would "pick the one in main.tf" and "recreate the lock file". Wrong on both: it reads the lock file and reuses it.

### Terraform reads every `*.tf` file in the folder

`main.tf`, `variables.tf` and `outputs.tf` are only convention. Terraform loads all of them as one config. `main.tf` does not "point to" the other files.

> Check: I said main.tf would point it to the other files. It doesn't.

### Input variables

```hcl
variable "filename" {
  type        = string
  description = "Name of the file to create"
  default     = "hello.bar"
}

variable "greeting" {
  type        = string
  description = "A greeting"
}
```

- The label is what I refer to later as `var.filename`. The description is for the next reader, so it should say what the variable is for.
- A variable with **no default and no value given** makes `plan` stop and ask (`Enter a value:`). It does not just warn. It only fails outright where no one can answer, like CI.
- At that prompt I typed `yes` as the value, so `yes` became the greeting. `yes` is for the `apply` confirmation, not for variable prompts. Read each prompt.
- `terraform fmt` rewrote my tab-indented `variables.tf` and printed its name. `terraform validate` checks syntax and references only, so passing it does not mean `apply` will work. Habit: `fmt`, `validate`, `plan`.

### Where a value comes from, and which wins (lowest to highest)

1. `default` in the variable block
2. `TF_VAR_name` environment variable
3. `terraform.tfvars` (and `*.auto.tfvars`)
4. `-var` and `-var-file` on the command line

A higher one beats every one below it. I tested: `-var` beat `terraform.tfvars`, and **`terraform.tfvars` beat the environment variable** (I predicted the opposite).

> Check: I predicted env would beat tfvars. It doesn't.

- Committing `variables.tf` is right, since the config needs the variables to run. `terraform.tfvars` holds the *values*, which often include secrets, so teams ignore `*.tfvars` and commit an example file (same idea as `.env` and `.env.example`).

### Locals

```hcl
locals {
  full_path = "${path.module}/${var.filename}"
}
```

- The block is `locals` (plural). A reference is `local.full_path` (singular). I wrote `local.fullpath` first (missing the underscore); `terraform validate` catches this kind of slip.
- A **variable** is an input someone outside can set. A **local** is a named computed value inside the config; nobody outside can set it. I tried `-var 'full_path=/tmp/x'` and Terraform refused it, because there is no such variable.
- For one reference, write `filename = local.full_path`. The `"${...}"` wrapper is for mixing text with references.

### Idempotent

Running the same config with the same input again changes nothing. My second `apply -var 'greeting=hello'` printed `No changes. Your infrastructure matches the configuration.` A bash script with `echo hello >> file` adds another line each run.

### Outputs

```hcl
output "file_path" {
  value       = local_file.hello.filename
  description = "Where the file was written"
}

output "content_sha256" {
  value       = local_file.hello.content_sha256
  description = "SHA-256 fingerprint of the file's content"
}
```

- An output is a value I chose to **report** after an apply, for a human (an address or URL) or for a program. Resources are what Terraform makes; outputs are not.
- `content_sha256` is an attribute the `local_file` resource **exports**. I never write it, the provider computes it. The provider's documentation lists these under "Attributes Reference".
- An apply that only adds outputs shows `Changes to Outputs` and says it will save them to state "without changing any real infrastructure". Outputs live in the state file.
- `terraform output` lists them. `terraform output -raw file_path` prints the bare value with no newline, which is what scripts want.
- `sha256sum hello.bar` matched `terraform output -raw content_sha256`: a fingerprint of the content, same idea as an image digest.

> Check: my first `content_sha256` output used `.content` (the file's text) instead of `.content_sha256`.

### Replace, re-tested

Changing `greeting` in `terraform.tfvars` and running `plan` showed `-/+`, "must be replaced", `# forces replacement` next to `content`, and `Plan: 1 to add, 0 to change, 1 to destroy`. The `content_sha256` output shows `-> (known after apply)`.

- A replace is harmless on a file. On real infrastructure it deletes the old thing first: a database with its data, or a server whose new copy gets a new IP address and may mean downtime. That is why I read for `-/+` before typing `yes`. (My first reason, "the hashes change", was a side effect, not the danger.)

## Block 6: the AWS provider, read-only

- The AWS provider is large: `.terraform` was **772 MB**, because the provider knows every AWS service.
- No keys in `main.tf`. The provider looks where the AWS CLI looks: **environment variables first, then the files in `~/.aws`**. My `aws login` session was found directly, so no fallback command was needed. Keys stay out of `.tf` files because those files go to Git, and a key in Git history stays there even after the line is deleted.
- `resource` = something Terraform **creates and manages**. `data` = something that already exists that Terraform only **reads**. Reference form: `data.<type>.<name>.<attribute>`.
- A plan with only data blocks has **no `Plan: N to add` line**. It shows only `Changes to Outputs` and says it will save outputs without changing real infrastructure. Reading is free and counts as zero resources.

> Check: I predicted "three resources" by counting blocks in the file. The answer was zero.

- I read `aws_caller_identity`, `aws_region` and `aws_availability_zones`. `terraform output` showed the same identity as `aws sts get-caller-identity`.
- **Zone names vs IDs:** AWS maps names (`eu-central-1a`) to physical zones differently in each account, so the same name can be a different building in another account. The ID (`euc1-az1`) always means the same zone. It matters when two accounts must run things in the same physical zone, because cross-zone traffic costs money and adds delay.
- State now holds the account ID, the ARN and the outputs. It stays out of Git.
- `terraform destroy` here printed `Destroy complete! Resources: 0 destroyed`: only the outputs were cleared from state, because nothing real was ever managed.
- Spelling slip to remember: the block type (`aws_availability_zones`) is a name the provider knows, and the label after it is what I refer to later. A misspelling in either stops the config.

## Reading an IAM policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
```

- `Effect` is `Allow` or `Deny`. `Action` is `service:Operation`, wildcards allowed. `Resource` is which things, by ARN.
- **Three rules:** everything is denied by default; an `Allow` opens only what it names; an explicit `Deny` beats any `Allow`.
- Exercise A: `s3:ListBucket` on `arn:aws:s3:::reports` plus `s3:GetObject` on `arn:aws:s3:::reports/*` means I can download a file but not delete one. There are two Resource lines because listing is an action on the **bucket** and getting is an action on the **objects inside it** (`/*`).
- Exercise B: `AdministratorAccess` is `Allow` / `*` / `*`: everything on everything. That is the **opposite** of least privilege. For Project 2, write a policy that names only the actions and resources the project uses.
- Exercise C: `Allow s3:*` on `*` plus `Deny s3:DeleteBucket` on `*`: I cannot delete a bucket (the Deny wins), but I can delete an object in it (`s3:DeleteObject` is covered by `s3:*` and not denied).
