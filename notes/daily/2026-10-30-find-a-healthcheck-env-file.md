# Finding a healthcheck myself, and env_file

Fri 30 Oct 2026. Labs: `projects/pg-health` (new), `projects/visit-counter`.

## One-line models

- **A healthcheck result is an exit code.** The command runs inside the container, and Docker only reads 0 (pass) or non-zero (fail).
- **`.env` fills in `compose.yaml`, `env_file:` hands in a bundle of defaults, and `environment:` wins when they clash.**

## Finding a healthcheck for a service I don't know

1. Identify the type of service and what check it would run (database/cache → its own client; web app → a request to a health route; anything else → is the port open).
2. Look for the check in the container (`ls /usr/local/bin`, `/usr/bin`, `docker history`) or in the documentation.
3. Test the command by hand with `docker exec`, and use the documentation to check its defaults.
4. Write the compose file.
5. Test that it works normally **and** with a case that fails.

```bash
sudo docker run -d --name pg-test -e POSTGRES_PASSWORD=test postgres:16
sudo docker exec pg-test pg_isready; echo $?            # accepting connections, 0
sudo docker exec pg-test pg_isready -p 9999; echo $?    # no response, 2
```

- Postgres is a database, so its own client asks "are you up?": `pg_isready`. I found it myself and confirmed the exit codes in the online docs (`--help` didn't list them).
- The docs list a different code for "no response" (2) than for "starting up but rejecting connections". Docker doesn't care which non-zero number it is.

> Check: the result is an exit code because the check is a command run inside the container, and every tool reports success or failure that way. An HTTP status like 200 belongs to web apps, and only works if a tool turns it into an exit code first (for example `urlopen` raising on a 500 so Python exits 1).

> Check: if the `test:` line has one wrong character, the check fails for the wrong reason. `pg-isready` is not `pg_isready`. Compare the line letter by letter with the command that worked when I tested it by hand.

### The compose file I wrote

```yaml
services:
  pg-test:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: test
    healthcheck:
      test: ["CMD", "pg_isready"]
      interval: 10s #time between checks
      timeout: 3s #time given to perform each check
      retries: 3 #failures in a row before "unhealthy" (about 30 s at this interval)
      start_period: 5s #grace window while the program boots: failures don't count
```

> Check: `retries` is not "the number of checks that can be performed". Checks keep running forever. It is how many **failures in a row** it takes to switch to `unhealthy`. One pass resets the streak.

`compose ps` showed `Up 17 seconds (healthy)`, and still `(healthy)` after about a minute.

### Proving it can fail

I changed the test to `["CMD", "pg_isready", "-p", "9999"]` and recreated the container. It went `unhealthy`, and `inspect` showed `ExitCode: 2` and `Output: ... :9999 - no response`.

- A check I have only seen pass is unproven. It is only useful if it also fails when something is wrong.
- `FailingStreak` counts consecutive failures. The log keeps only the last five.

## The timing fields

| Field | What it is |
|---|---|
| `interval` | the gap between checks (counted from the end of the previous one) |
| `timeout` | how long **one** check may run before it counts as failed |
| `retries` | how many failures in a row before `unhealthy`, so one blip doesn't trigger it |
| `start_period` | a grace window: failures inside it don't count, and a pass inside it makes the container healthy straight away |

> Check: these are not added together. `timeout` is a cap on a single check, not part of the interval. `start_period` is not a delay in front: checks still run during it, they just aren't counted. With `retries: 3` and a 10 s interval, `unhealthy` arrives after roughly 30 seconds of failures, not 8.

My reasoning for the values, written from measuring rather than guessing:
- `interval: 10s`: `pg_isready` is very cheap, so asking every 10 s costs nothing, and 10 s × 3 retries means a broken database shows in about 30 s.
- `timeout: 3s`: the check is very fast, so 3 s is plenty and still shorter than the interval.
- `retries: 3`: about 30 s of failures before it reports unhealthy, which is reasonable.
- `start_period: 5s`: Postgres boots in a second or two, plus a couple of seconds to set itself up on a fresh start. Retries add more slack on top.

## env_file

```yaml
    env_file:
      - app.env
```

Results with `app.env` holding `REDIS_HOST=redis` and `HOST_PORT=9000`:

- `docker compose config` shows `REDIS_HOST` and `HOST_PORT` under `environment:` of the service, and `exec app env` prints both.
- The published port stayed `8000`. `HOST_PORT=9000` went into the container only.
- With the same variable in `app.env` and in `environment:`, the container got the `environment:` value.

| | Fills in `compose.yaml`? | Reaches the container? |
|---|---|---|
| `.env` | yes, for `${VAR}` | no, not on its own |
| `environment:` | no | yes, and it **wins** |
| `env_file:` | no | yes, as defaults |

> Check: `env_file` doesn't change `${HOST_PORT}` in the compose file. Only `.env` does that. Nothing "overwrote" the port, because nothing competed for it. Two files, two jobs.

## Weeks 3–4 closed

Dockerfiles and multi-stage builds, non-root and hardening, Compose with health checks and environment variables, volumes and networking, secrets, a registry push, and the visit-counter app with Redis. Next: Week 5, CI/CD with GitHub Actions, starting Mon 2 Nov.
