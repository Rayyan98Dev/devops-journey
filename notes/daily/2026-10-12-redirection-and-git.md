# Mon 12 Oct: Redirection and Git

*My own wording, spelling tidied. A **Check:** line is a correction we agreed on.*

## Redirection
- I was still thinking `2>&1` made stream 2 part of stream 1, when really it just sends stream 2 to wherever stream 1 is pointing at that moment.
  - **Rule:** redirections run left to right. `> out.txt 2>&1` puts both in the file; `2>&1 > out.txt` leaves the error on the screen.
- Bash arrays are a list of strings; bash stores everything as text, and only arithmetic treats it as numbers.
## Git: commits, branches and merges
- `HEAD` is really just what branch I'm currently on. Like a "you are here" marker.
- `.git/refs/heads/` stores my branches, one file each.
- A branch is really a file that stores the hash of the commit the branch points to. It always holds the newest commit made on it.
  - Like a bookmark on the newest picture, not an album.
- A commit is really a snapshot of the tree taken at that time, i.e. the folders and files.
  - **Check:** plus a `parent` link to the previous commit, the author, the time and a message. The hash is its ID.
  - Like a picture *plus* its metadata (who, when, caption, which picture came before).
- Two branches had the same hash because they both pointed to the same commit. A new branch copies nothing.
- A merge is really the combining of two branches' commits. It makes a commit with two parents, but if one branch has nothing new compared with the other, it just fast-forwards: it moves the label to the branch with the new stuff.
  - Like superimposing two pictures; if one picture has nothing the other lacks, you just use that picture (fast-forward).
- GitHub also stores its own branch files; that's how it tells branches apart.
- Fifteen branches don't cost fifteen copies: a branch is one small file, and Git stores each file version once.

## Git: remotes, fetch, pull and push
- `origin/main` is really just a local copy to compare my working branch with.
  - **Check:** it's a local *bookmark* of where the remote's `main` was at my last push or fetch, not a copy of files. It doesn't move when I commit.
- `git fetch` is really a check of `origin/main` against the remote branch to see if it's up to date, and `git pull` is a combination of `git fetch` and merge.
  - **Check:** `fetch` *downloads* new commits and moves the `origin/main` bookmark. It never touches my branch or files. `git status` does the comparing afterwards.
- A push is accepted if the parent commit on the branch I'm pushing from matches the commit on the remote.
  - **Check:** the remote's current tip must already be somewhere in the history I'm pushing (not necessarily the direct parent).
- Ahead means my branch has commits `origin/main` lacks. Behind means `origin/main` has commits my branch lacks. Diverged means both have commits the other lacks.

| State | `git status` says |
| --- | --- |
| ahead | "ahead of 'origin/main' by N commits" |
| behind | "behind 'origin/main' by N commits, and can be fast-forwarded" |
| diverged | "have diverged, and have 1 and 1 different commits each" |

