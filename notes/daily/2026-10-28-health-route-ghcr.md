# /health route, web healthcheck and GHCR push

Wed 28 Oct 2026. Lab: `projects/visit-counter`. Image: `ghcr.io/rayyan98dev/visit-counter`.

## One-line models

- **`/health` route:** a question the app answers about itself: "are you alive?"
- **Shallow vs deep check:** shallow asks if the app is answering; deep asks if specific parts work too, like talking to Redis.
- **Layers vs manifest:** layers are the contents of the image; the manifest is the label that points to those layers.
- **Version tag vs SHA tag:** one is easy for humans to read; the other points to the commit the image was built from, so I can see exactly what code is in it.

## The `/health` route

```python
@app.route("/health")
def health():
    return ("Working fine", 200)
```

- The healthcheck hits `/health`, not `/`, because `/` adds to the visit counter (or runs whatever the app really does), so every check would make the count wrong and waste work.
- Proven: `/` gave 7, `/health`, then `/` gave 8. The health call didn't count.
- `return 200` failed because Flask expects a response body, with the status code as an optional second item: `return ("body", 200)`.

> Check: a bare number isn't a valid response, so Flask raises an error and sends a **500**. A healthcheck on that route would mark the container unhealthy.

## The web healthcheck

```yaml
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
```

- Python's `urlopen` instead of `curl`, because `curl` isn't installed in the slim image but Python is.
- `CMD-SHELL` is for when I need the shell to do something: chain (`&&`), pipe (`|`), redirect (`>`), or expand `$VARIABLES`. `CMD` just runs the command, so it's right here.
- `start_period` is a grace period where failures don't count, giving the app time to boot.

> Check: checks still run during `start_period`. A **pass** inside it marks the container healthy straight away, which is why mine was `(healthy)` by 14 s.

- Right after start, `compose ps` shows `Up Less than a second (health: starting)`. After the first pass: `(healthy)`.
- `timeout` should be shorter than `interval` (3 s, not 10 s), so a hung app fails fast.

### Testing the check by hand first

```bash
sudo docker compose exec app python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"; echo $?   # 0
sudo docker compose exec app python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/nope')"; echo $?     # 1
```

- The `/nope` traceback wasn't the app crashing. It showed the error: the app answered normally with a 404 (endpoint not found).

> Check: the traceback came from `urlopen` in the check script, which raises `HTTPError` on any 4xx or 5xx. Python exits 1, so Docker would mark it unhealthy. That's the test working. A catch-all route returning 200 would make a typo like `/helth` pass forever.

### Seeing the check history

> Check: `compose ps` is a snapshot. The history is in `inspect`, not "instance":

```bash
sudo docker inspect --format '{{json .State.Health}}' visit-counter-app-1
```

It shows `Status`, `FailingStreak` and the last five checks with `ExitCode` and `Output`. Mine were five checks, about 0.4 s each, 10 s apart, all exit 0.

## Pushing to GHCR

1. Classic token with only `write:packages`, 30-day expiry. Never paste it anywhere.
2. `sudo docker login ghcr.io -u Rayyan98Dev --password-stdin` (paste, Enter, Ctrl-D).
3. Tag, then push each tag.

- `docker login` stores the creds in the user's `~/.docker/config.json`. `sudo` matters because then they go in **root's** (`/root/.docker/config.json`), and `sudo docker push` only reads root's.
- Capitals are fine in `-u Rayyan98Dev`. The lowercase rule is for image names only.
- `Login Succeeded` only proves the token is valid. The push can still fail: missing scope, capitals in the image name, or a package owned by someone else.

### Image name

The name needs the registry, my username and the image name with a tag.

> Check: the order is `registry/namespace/repo:tag`, so `ghcr.io/rayyan98dev/visit-counter:0.1.2`. Without the `ghcr.io/rayyan98dev/` prefix, Docker treats it as a local or Docker Hub name. The repo part must be lowercase because Docker's reference format doesn't allow capitals.

```bash
sudo docker tag visit-counter-app ghcr.io/rayyan98dev/visit-counter:0.1.2
sudo docker tag visit-counter-app ghcr.io/rayyan98dev/visit-counter:b1e2dff   # git rev-parse --short HEAD
```

- Typos don't warn you: `visit-couter` would have happily created a second package.
- `image ls` showed three rows with one ID (`18c30729405a`): one image, three names.

### What the pushes showed

- Only the first push uploaded layers, because the second had the same layers, so there was no need to make duplicates (`Layer already exists`).
- Both tags came back with the **same digest** (`sha256:18c3...`): one image, two names in the registry too.
- The first push uploaded every layer and then said `denied`. The layers existed, but with no manifest there was nothing identifying them and pointing to them, so `0.1.2` couldn't be pulled. Pushing again worked.

> Check: the cause of that first `denied` isn't confirmed. It was probably a one-time hiccup while GHCR created the package. See the bug journal.

- Prove a push worked with `docker pull` of each tag. A `digest:` line at the end of a push means the manifest was accepted.

## Still to do

- Check the package on `github.com/Rayyan98Dev?tab=packages`: is it private (the default)? Link it to the repo with the label `org.opencontainers.image.source`.
- Thursday: environment variables in Compose, and keeping secrets out of the image.
