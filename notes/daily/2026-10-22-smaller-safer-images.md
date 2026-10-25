# Thu 22 Oct: Smaller, safer images

*My own wording, spelling tidied. A **Check:** line is a correction we agreed on. Project: `projects/visit-counter/`.*

## Models
- The build context is everything in the folder sent to the builder, and `COPY` picks what it needs from it. With BuildKit, only what the Dockerfile needs is sent.
  - **Check:** it's the *folder* you pass to `docker build` (the `.`), not a file. Only `COPY`/`ADD` move anything from the context into the image, and `RUN` can't see the context at all.
- A multi-stage build has multiple `FROM` lines. Each `FROM` is a stage, and the last stage is the image. `COPY --from=` decides what is taken from earlier stages, and anything not taken is discarded.
  - **Check:** I first wrote "a compose with multiple `FROM`". It's a **Dockerfile**. Compose is a separate file.
- `USER` sets the program to run as non-root.
  - **Check:** more precisely, `USER` sets the user for every later `RUN` line and for the container's process (`CMD`/`ENTRYPOINT`). Lines before it still run as root.

## Where image size comes from
- An image's size is the bytes all its layers add, not how many layers there are. `WORKDIR`, `ENV` and `ENTRYPOINT` are 0B because they only change settings.
  - **Check:** I first guessed `ghuser` was bigger "by three to four layers". The real difference was about 12.7 MB, the `pip install` layer.
- The biggest layer in any Python image is the 86.7 MB Debian base that `FROM` brings in. Of my own lines, `pip install` was the biggest.
- DISK USAGE counts the compressed data and the uncompressed data, so a layer is counted about twice. CONTENT SIZE is the compressed download size.
  - Random junk doesn't compress, so my 50 MB file added 52.4 MB to CONTENT SIZE and 105 MB to DISK USAGE. Normal files compress a lot: 43 MB compressed is about 133 MB unpacked.
- Images on the same base share its layers, which are stored once.

## Deleting doesn't shrink an image
- Once a file is in a layer, that layer can't shrink. A later `rm` just adds a marker that makes the file invisible to the container (`RUN rm /junk` showed 0B in `docker history`, and the 52.4 MB layer stayed). Multi-stage builds are what you want for this.
  - **Check:** deleting in the **same** `RUN` line also works (`RUN download && use && rm`), because the file never gets saved in a layer.

| Experiment | Disk usage |
|---|---|
| base + junk, then `rm` in the next `RUN` (`ms-delete`) | 281 MB |
| junk only in the `builder` stage (`ms-multi`) | 176 MB, the same as the bare base |

- `AS builder` names a stage so `COPY --from=builder` can point to it. Unnamed stages are numbered from 0 (the build output showed `stage-1`). `--target builder` builds up to that stage only.

## `.dockerignore`
- It matters because it stops `COPY . .` from taking everything. BuildKit only takes what the Dockerfile needs, but if the Dockerfile says everything, it takes everything.

| `COPY . .` test | Context sent | Image |
|---|---|---|
| no `.dockerignore` | 52.44 MB | 281 MB |
| `big.bin` in `.dockerignore` | 509 B | 176 MB |

- With the normal visit-counter Dockerfile (only `COPY requirements.txt` and `app.py`), `big.bin` was never sent (181 B context) and the image didn't grow.
  - **Check:** I predicted the image would grow. Only what `COPY` names goes into the image. Claude predicted the 50 MB would still be sent, which was true for the old builder but not for BuildKit.
- Flags: `--progress=plain` prints every step as plain lines (needed for `grep`), `-f` picks the Dockerfile (file), and `-t` names the image (tag).

## visit-counter: multi-stage and non-root
```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim
RUN useradd --create-home --uid 10001 appuser
WORKDIR /app
COPY --from=builder /install /usr/local
COPY app.py .
USER appuser
CMD ["python", "app.py"]
```
- `docker run --rm visit-counter-app whoami` on the old image printed `root`. `whoami` ran because there's no `ENTRYPOINT`, so words after the image name replace `CMD`.
- After the change, `whoami` printed `appuser`, and the app still worked on port 8000 (non-root can use ports above 1024).
- Size went from 203 MB to 191 MB, a small saving (probably pip's own cache files left behind in `builder`). Multi-stage saves a lot when the build needs compilers the app doesn't.
- 191 vs 176 MB: the 15 MB is Flask, Redis and their dependencies. The fair comparison is the old visit-counter against the new one.

## What `USER` blocks
- `/app` and `app.py` are owned by `root root` (user and group), because `WORKDIR` ran before `USER`. So `appuser` can't change them: `touch /app/hack.txt` gave `Permission denied`.
  - **Check:** I first assumed `appuser` could write to `/app`.
- `/tmp` is open to everyone, so `touch /tmp/ok.txt` worked.
- `USER` protects against the program reaching root-level things, but it doesn't stop someone who has access to the computer and can run docker commands: `docker compose exec -u root app whoami` printed `root`.
  - **Check:** I assumed Docker would ask for root credentials, or has default ones. Docker has no credentials. Anyone who can reach `docker.sock` is trusted, and the fingerprint prompt was `sudo`.
- `docker exec` uses container names (`visit-counter-app-1`), and `docker compose exec` uses service names (`app`).

### Privilege escalation
- Getting from `appuser` to root. A script `appuser` writes still runs as `appuser`, so escalation needs a flaw: a root program `appuser` can trigger (setuid, loose `sudo`), a file root runs later that `appuser` can edit, or a kernel bug (containers share the host kernel).
- Defences: slim images, no `sudo` in images, `appuser` owns only what it must write, `no-new-privileges`, rootless Docker.

## Teach-back
- `.dockerignore` is useful for stopping files and data I don't want from getting into the image. `COPY . .` is a bad idea since it takes everything.
  - **Check:** `COPY . .` is fine with a good `.dockerignore`. Without one, it's risky.
- Multi-stage builds are a better way to handle files and folders I need at one point but not in the final image: `COPY --from=` chooses what goes into the final image, and the rest is discarded.
- `USER` is a good way to stop a hijacked program, or one with unintended consequences, from doing things at root level.

## Time log
- Block 1: 09:45 to 10:50 (quiz first; Round 1 ran over, so multi-stage moved to Block 2).
- Break: 10:50 to 11:12.
- Block 2: 11:12 to about 11:55, commit by 12:05.
- Wrap-up: 12:03 to 12:10.
