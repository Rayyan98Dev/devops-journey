# Healthchecks, tags and registries

Tue 27 Oct 2026. Lab: `projects/visit-counter`.

## One-line models

- **Healthcheck:** a question Docker asks the container on an interval. Exit 0 = pass. The answer is only as good as the question.
- **Image reference:** the address of an image: `registry/namespace/repo:tag`.
- **Registry:** a git remote for images. `push` only uploads the layers it's missing ("Layer already exists").
- **Dockerfile → image → container:** recipe → frozen result → running copy.

> Check: the image is not the recipe. The Dockerfile is the recipe; the image is the finished result of following it.

## Tag vs digest vs image ID

|          | Who creates it        | Can it change? | What it identifies                                  |
|----------|-----------------------|----------------|-----------------------------------------------------|
| tag      | me (or Docker's `latest` default) | yes, it moves | a name for an image, often a version or git SHA |
| digest   | registry, on push/pull | no            | the image on the remote registry                     |
| image ID | Docker, on build      | no             | the image on my machine                              |

- `latest` is just the default tag name. It doesn't mean newest.
- A second tag is a **pin**, not a copy or backup. `visit-counter-app:latest` and `web:0.1.1` both had ID `2edee0ee979b`: one image, two names.
- After a rebuild, `latest` moved to the new image (`3a9a60459162`). `web:0.1.1` stayed on the old one, so no `<none>` row appeared.

## Running vs healthy

- **Running:** the container's main process hasn't exited.
- **Healthy:** the healthcheck command passed.
- Health states: `starting` → `healthy` or `unhealthy`.

| | Reacts to | What it does |
|---|---|---|
| restart policy | the process **exiting** | restarts the container |
| healthcheck | the check command failing | only changes the label to `unhealthy` |

> Check: plain Docker and Compose **never** restart a container because it's unhealthy. Only orchestrators (like Kubernetes) act on health.

## depends_on: before vs after `service_healthy`

- Plain `depends_on`: services start in order, but `app` doesn't wait for Redis to be ready.
- With `condition: service_healthy`: `app` waits until Redis passes its check. Output: `Redis Healthy 5.3s`, then `app Started 5.4s`.

> Check: `starting` / `healthy` / `unhealthy` are a container's own health states, not `depends_on` states. What changed is whether `app` *waits*.

My Redis healthcheck:

```yaml
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
```

`compose ps` after `up -d`: redis `Up (healthy)`, app plain `Up` (no healthcheck yet).

## Finding a healthcheck for any service

1. What kind of service is it? Database/cache → its own client (`redis-cli ping`, `pg_isready`). Web app → HTTP request to `/health`. Anything else → is the port open (weakest).
2. Look inside the image: `ls /usr/local/bin`, `/usr/bin`, and tools sharing the main program's prefix.
3. Read the tool's `--help` for defaults (`redis-cli` defaults to `127.0.0.1:6379`, so no flags needed).
4. Test by hand: `docker exec <container> <cmd>; echo $?`. Healthy = 0.
5. Only then write the `healthcheck:` block.

- `inspect` shows how an image **runs** (CMD, env, ports). `ls`, `docker history --no-trunc` or a shell show what it **contains**.
- Distroless/`scratch` images have no shell, so `docker run ... bash` fails on them.

## Gotchas

- `redis-cli ping` replies `PONG`. `redis-server` would try to start a second server and fail because port 6379 is taken.
- `docker login` saves credentials for whichever user ran it. `sudo` makes that root, and `sudo docker push` only reads root's credentials. Without matching logins → `denied`.
- Repo names must be lowercase: `ghcr.io/Rayyan98Dev/web` → `invalid reference format`. Use `ghcr.io/rayyan98dev/web`.
- New GHCR packages are private by default. Link to the repo with the label `org.opencontainers.image.source`.
- The web healthcheck must hit `/health`, not `/`, because `/` adds to the visit counter.

## Still to do (Wed 28 Oct)

- `/health` route in `app.py` + web healthcheck (Python `urllib.request.urlopen`, no curl in the slim image)
- GHCR token, tag with version and `$(git rev-parse --short HEAD)`, push
