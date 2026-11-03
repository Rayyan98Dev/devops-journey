# CI on pull requests, and protecting main

Tue 3 Nov 2026 (Week 5). Repo: `devops-journey`. Lab: `projects/visit-counter`.

## One-line models

- **`push` tests the commit I pushed. `pull_request` tests what `main` would look like after the merge.**
- **A required check is a door in front of `main`.** The commit has to pass on a branch first, so nothing reaches `main` untested.
- **A rule only protects while it is Active.** A ruleset that is Disabled is a draft.

## The two triggers

```yaml
on:
    push:
        branches: [main]
    pull_request:
```

| | `push` | `pull_request` |
|---|---|---|
| When it runs | every time I push (here: only to `main`) | when a PR is opened, and again on every push to the PR branch |
| What it tests | the code of the pushed commit | a temporary merge of the PR into `main` |
| Label next to the check | `(push)` | `(pull_request)` |

- Without `pull_request:` in `on:`, opening a PR starts nothing. The first PR showed no checks at all.
- `push:` with no branch filter runs for every branch push, and then a PR also runs. That is two runs for the same code, so the push trigger is limited to `main`.

> Check: the word in brackets next to the check name tells me which trigger ran. On my first PR it still said `(push)`, which showed the PR trigger had never been added. The `on:` change was only on my laptop. GitHub reads the workflow from what I **pushed**, so an unpushed edit changes nothing.

## `git push -u origin <branch>`

- `git push origin <branch>` creates the branch on GitHub if it doesn't exist. The name tells Git where to send it.
- `-u` (`--set-upstream`) also remembers the link, so a plain `git push` works afterwards.
- Plain `git push` on a new branch fails with `fatal: The current branch ... has no upstream branch`. Git prints the fix.

> Check: being on the branch locally doesn't make it exist on GitHub. Local and remote are two separate places with their own branches.

## Reading a failed pytest run

I broke a test on purpose: `assert response.status_code == 201`.

- Read the failing test name, the `assert` line with both values (`assert 200 == 201`), and the line number in `test_app.py`.
- Then read the exit code: **1** means a test failed. **5** means no tests were collected. **127** means command not found.
- A red PR shows `All checks have failed`, and the merge button is greyed out once a check is required.

> Check: the exit code says *what kind* of failure it is. The `assert` line says *what exactly*. I need both lines, not only the first.

## Protecting `main` with a ruleset

Settings, Rules, Rulesets. My ruleset `protect-main`:

| Setting | Value |
|---|---|
| Target | the default branch (`main`) |
| Restrict deletions | on |
| Require status checks to pass | on, `simple-job` (GitHub Actions) |
| Block force pushes | on |
| Bypass list | empty |
| Enforcement status | **Active** |

- The ruleset exists after I create it, but **Enforcement status: Disabled** protects nothing. My PR's merge button stayed usable until I switched it to Active.
- An empty bypass list means the rule applies to me too. Being the repo owner doesn't exempt me. Only a bypass entry does.
- The required check is found by the **job name** (`simple-job`), not the workflow name.

> Check: if I rename the job, the required name never reports. The check doesn't pass and doesn't error: GitHub keeps waiting for it (`Required status check "simple-job" is expected`), so every merge stays blocked. A mistake here fails closed. If I rename the job, I change the ruleset in the same PR.

## A straight push to `main` is refused

```
remote: error: GH013: Repository rule violations found for refs/heads/main.
remote: - Required status check "simple-job" is expected.
 ! [remote rejected] main -> main (push declined due to repository rule violations)
```

- The commit has to be tested before it may land on `main`. A commit pushed straight to `main` has never been tested, so it can't have a green check.
- It doesn't matter how healthy the tests are. The rule is about the order, not the result.

### Notes workflow from now on (my decision: no bypass, so I build the habit)

1. `git switch -c notes-YYYY-MM-DD`
2. edit, `git add <file>`, `git commit -m "..."`
3. `git push -u origin notes-YYYY-MM-DD`
4. open the PR, wait for the green check, merge
5. `git switch main`, `git pull`

If I commit on `main` by mistake: `git reset --soft HEAD~1` undoes the commit and keeps my edit staged. Then `git switch -c <branch>` carries the staged edit onto a branch. If the commit is kept instead, `git switch -c <branch>` then `git branch -f main origin/main` moves it and puts `main` back.

> Check: `branch -f main origin/main` moves only a label. The commit stays reachable from the new branch, so nothing is lost.

## Still to do

- Wed: build the Docker image and push it to GHCR from Actions. Hand-write the Dockerfile and compose first.
- Thu: scan the image for vulnerabilities.
- Fri: review, and the Project 1 README.
