# Tue 13 Oct: Git conflicts, rebase and pull requests

*My own wording, spelling tidied. A **Check:** line is a correction we agreed on.*

## Merge conflicts
- A merge conflict is really a conflict on the same line between two branches.
  - **Check:** two *branches* changing the same line of the *same file*. Git stops the merge and asks me to choose.
- The markers show what I have and what I'm bringing in from the branch I'm merging. `HEAD` means the branch I'm on.
  - This is not the case with rebase, since it goes through each commit, so it's better to read the actual content before deciding.
- To finish a merge after resolving the conflict: `git add`, then `git commit`. `git merge --abort` backs out.

## Rebase
- A rebase is really like taking the commits from one branch and sticking them at the tip of the other branch.
  - **Check:** rebase isn't a merge. It moves *my* branch's starting point; the other branch isn't touched.
- The hashes change because they have new parents, and that spreads down the chain: the first copied commit gets the other branch's tip as its parent, so the next commit's parent changes too, and so on.
- A commit is a snapshot of the files and folders, plus the name, timestamp and PARENT.
  - **Check:** author and committer (name, email, time), parent(s), and a message.
- The old commits are still there, they just lose their labels, and can be brought back using `git reflog`.
  - **Check:** there's no `git rescue`. What I ran was `git branch rescued 9aab82e`, a new label on the old commit. The reflog is local only.

## Rebase conflicts
- Mostly the same as a merge conflict, but after resolving I run `git add`, then `git rebase --continue`. A text editor may open; save and close it.
- In a rebase conflict, `HEAD` doesn't mean the branch I'm on.
  - **Check:** `HEAD` is the side being built: `main` plus any commits already replayed. The other side is my commit being replayed.
- `git branch` showed `HEAD` not pointing to any branch: a detached `HEAD`.
  - **Check:** detached `HEAD` means `HEAD` points straight at a commit instead of at a branch. Git re-attaches it when the rebase finishes.

## Rebase diagrams (drawn by hand)
- Start: `main` is `A - B - C`, and `branch` is `D - E - F`, split off at `B`.
- Rebase `branch` onto `main`: `A - B - C - D' - E' - F'`, with `main` at `C` and `branch` at `F'`.
  - **Check:** correct result, but it's a rebase (`git rebase main` while on `branch`), not a merge.
- Rebase `main` onto `branch`: I drew `D - E - F - A' - B' - C'`.
  - **Check:** only commits the target doesn't have get copied. `A` and `B` are shared, so only `C` is copied: `A - B - D - E - F - C'`, with `branch` at `F` and `main` at `C'`.
- Where `HEAD` sits during a rebase conflict: on the last commit built so far (first `C`, then `D'`, and so on). The branch label only moves at the end.

## Merge vs rebase
| | merge | rebase |
|---|---|---|
| New commits | one merge commit (only when needed; a fast-forward makes none) | a copy of every commit on my branch |
| My existing commits | keep their hashes | replaced by copies with new hashes |
| Shape | keeps the diamond | a straight line |
| Conflicts | resolved once | maybe once per commit |
| Safe on shared branches? | yes | no |

- The question that decides: does anyone else already have these commits?
  - **Check:** "will it be pushed?" alone doesn't decide. A pushed branch only I use can be rebased, pushed with `--force-with-lease`.
- Example of it going wrong: someone rebased commits the other person **already had**, then **force-pushed**. When the other person pulled, Git mixed the old commits with the new copies, so the same changes showed up twice with different hashes.
- Other ways it goes wrong: a force-push can wipe a coworker's commit from the remote, and a hash written in a ticket stops existing.

## Pushing a new branch
- **Check:** a plain `git push` on a brand-new branch fails with "has no upstream branch".
- `git push -u origin <branch>` pushes it and sets the link.
- **Check:** an upstream is really a link between my local branch and its remote branch (`add-readme` and `origin/add-readme`), so plain `push` and `pull` know where to go.
- It adds a new bookmark, `origin/<branch>`. `git branch -vv` shows the link in square brackets.

## Pull requests
- A pull request is really a request to review and merge a branch. It's a GitHub feature, not a Git one.
- **Check:** the PR page caught the extra commit: 2 commits and 2 files, because I created `add-readme` while on `clash`. Lesson: run `git status` before `git switch -c`.
- GitHub's merge button defaults to a merge commit with two parents, while `git pull` fast-forwarded because my local `main` had nothing new.

## Undoing things
- `git reflog` is for when a commit is no longer part of the chain, for example after a rebase or after deleting an unmerged branch.
- **Check:** `git revert` doesn't roll back to a commit. It makes a new commit that undoes one commit's changes.
- **Check:** revert is safe on shared branches because it adds to history and rewrites nothing. `git reset --hard` moves the label back, which rewrites history.
- Revert is really an undo commit.

## Yesterday's fixes
- A commit also contains the parent.
- `> out.txt 2>&1`: stream 1's destination is the file, and stream 2 is pointed wherever stream 1 is going, which is the file.
- `2>&1 > out.txt`: stream 2 is pointed at stream 1's destination, the screen. Then stream 1 is pointed at the file, which doesn't go back and change stream 2.

## Teach-back
- Rebase is not a merge. It copies the commits and rehashes them because they have new parents, and makes those copies the new tip of the branch. It brings in what my branch didn't have, and if there's a conflict I resolve it like in a merge.
  - **Check:** only the first copy's parent is the other branch's tip; each later copy's parent is the copy before it.
- Rebase shouldn't be used on shared branches: it can cause duplicates of the same changes with different hashes, or break things that point to a hash.
- `git push -u origin <branch-name>` pushes a new branch to GitHub.
- Git's default merge is `ort`.
  - **Check:** `ort` is the algorithm that combines changes. It's a separate question from fast-forward vs merge commit.
- Rebase is for branches only I work on, and can be used to tidy commits.
