# Environment variables and secrets

Thu 29 Oct 2026. Lab: `projects/visit-counter`, plus `leak-test`.

## One-line models

- **Config belongs outside the image.** The image is the same everywhere; the environment decides the settings.
- **An image is a public record of how it was built.** Secrets go in at run time, never at build time.
- **A Compose secret is a file** from my laptop, mounted into the container at `/run/secrets/<name>`. It is not part of the image.

## Environment variables

- `os.environ.get("REDIS_HOST", "redis")`: the `"redis"` is a default that lives in the **code**. `env` shows only what something actually set, so before I added `environment:` it printed nothing.
- A hostname is not a path. Docker's DNS turns `redis` into the container's IP.
- Better to set it in `compose.yaml`: the same image runs anywhere (laptop, AWS) and only the compose file changes, with no edit to the code and no rebuild.

> Check: the default only applies when the variable is **missing**. If it is set to an empty string, `get()` returns `""`, so `"redis"` does not save me.

| | Read by | Reaches the container? |
|---|---|---|
| `.env` file | Compose, to fill in `${VAR}` inside `compose.yaml` | no, not on its own |
| `environment:` | the container, per service | yes |
| `env_file:` | a file listed under a service | yes, every line in it (lab on Fri) |

Proof: with `HOST_PORT` in `.env`, `config` showed `published: "8000"`, but `exec app env | grep HOST_PORT` printed nothing. `REDIS_HOST` printed, because `environment:` passes it on.

```yaml
    ports:
      - "127.0.0.1:${HOST_PORT}:8000"
    environment:
      REDIS_HOST: ${REDIS_HOST}
```

## The bad-host test

With `REDIS_HOST: wrong-host`: the container started, `/` returned a 500 (after the Redis client's retries, so it looked like a hang), and `/health` stayed `200` the whole time. `compose ps` said `(healthy)`.

- `/health` only proves the web process answers. It never talks to Redis.

> Check: a **deep** check would call Redis from `/health` and return an error if it fails, so the container goes `unhealthy`. Shallow can say healthy while the app is useless.

- `docker compose logs app` shows the real error: `Name or service not known` for the host.
- Not a crash: the Redis client connects on the first command (`r.incr`), not at startup.

## Secrets

### Leaking on purpose

```dockerfile
FROM alpine
ENV API_KEY=supersecret123
ARG BUILD_TOKEN
```

- `docker image inspect` showed `API_KEY=supersecret123`.
- `docker history --no-trunc` showed **both**: `ENV API_KEY=supersecret123` and `ARG BUILD_TOKEN=tok-abc`.

> Check: `ENV` is saved in the image's config, so `inspect` shows it. `ARG` is not in the config, but BuildKit writes it into the build record, so `history` shows it. Either way, anyone who can pull the image can read both.

### Compose secret

```yaml
    secrets:
      - api_key

secrets:
  api_key:
    file: ./secrets/api_key.txt
```

- Not in `env`, mounted at `/run/secrets/api_key`, and `inspect visit-counter-app` finds nothing.
- `secrets/` and `.env` are in `.gitignore`. `git status` doesn't list them.
- The path in `file:` is relative to the folder holding `compose.yaml`, so `secrets/` lives in `visit-counter/`.

> Check: files are safer than variables, not invisible. A variable shows up in `docker inspect`, can be printed in logs and is inherited by every child process. A file doesn't, but anyone who can `exec` into the container can still read it, and so can the app if it logs the contents. I log only the length.

```python
def sec():
    with open("/run/secrets/api_key") as secrets:
        key = secrets.read()
        key = key.strip()
        app.logger.warning("API key loaded (%d chars)", len(key))
```

- The log said `(14 chars)`. A file written with `echo` would be 15, because `echo` adds a newline. Hence `.strip()`.
- Plain Compose secrets keep the host file's owner and permissions. If I `chmod 600` the file, the container user (uid 10001) can't read it. Real setups fix this with matching IDs or a proper secret store (Kubernetes, Week 8).

## Gotchas

- A relative path like `run/secrets/api_key` starts from the working directory (`/app`), so the file isn't found. Absolute paths start at the root and always find it: `/run/secrets/api_key`.
- `print()` can be buffered in a container, so use `app.logger.warning(...)` to see output reliably.
- `up -d` reuses the old image. The code is baked in, so a code change needs `up -d --build`.
- `curl -r` means "range"; the verbose-header flag is `-i`.

## Commit checklist

- `app.py`, `compose.yaml` (check `timeout: 3s` is saved), `.gitignore`, notes, bug journal, parking lot, and `leak-test` moved to `docker-labs` with a README saying the values are fake.
