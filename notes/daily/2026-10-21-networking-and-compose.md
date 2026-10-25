# Wed 21 Oct: Docker networking and Compose

*My own wording, spelling tidied. A **Check:** line is a correction we agreed on. Project: `projects/visit-counter/` (Flask app + Redis).*

## Models
- A Docker network is really a local LAN for containers. They can find each other by name using Docker's built-in DNS. The names come from the service names in `compose.yaml`, while plain `docker run` uses the container names (`--name web`).
- A `compose.yaml` is really all the `docker build` and `docker run` commands written down once. It can set ports, make volumes, and so on, and `docker compose up` creates the network, the volumes and every container together.

## Networking experiment (nginx + an alpine "visitor")
- `docker network create labnet`, then nginx and the visitor both on `--network labnet`: `wget -qO- http://web` worked, by name only.
- A visitor not on `labnet` failed with `can't connect to remote host (127.0.53.53)`.
  - **Check:** I predicted a 404, but a 404 means the server was reached and the page is missing. Here the name never resolved to my container: without the shared network there's no Docker DNS, so "web" went to the normal internet DNS, which returned `127.0.53.53` (a special warning address), and nothing was there.
- No `-p` was needed for the visitor to reach nginx.

| Who connects | What they need |
|---|---|
| Container to container, same network | the name and the container's port (`http://web:80`, `redis:6379`) |
| My laptop or browser to a container | `-p` to publish the port onto the laptop |

- `-p` is for setting which IPs and ports are open. Redis doesn't need ports set, because the containers talk directly on the same network, so it doesn't need to be exposed outside.
  - **Check:** more precisely, `-p` publishes a container's port onto the laptop, and is only for traffic from outside Docker. In `compose ps`, `app` showed `127.0.0.1:8000->8000/tcp` (published), while `redis` showed just `6379/tcp` (open only inside the network). Redis listens on 6379, not 80 (80 was nginx).

## Compose file
```yaml
services:
  app:
    build: .
    init: true
    ports:
      - "127.0.0.1:8000:8000"
    depends_on:
      - redis
  redis:
    image: redis:7
    volumes:
      - redis-data:/data

volumes:
  redis-data:
```
- `app` finds Redis with the service name `redis` using the DNS service, and they talk through ports directly, since they're on the same network, named after the folder (`visit-counter_default`).
- Compose always makes one network per project, however many services there are.
- `image:` replaces the image name in a plain `docker run`. `build:` replaces the `docker build` command (build from the Dockerfile in this folder).
  - **Check:** I first guessed that `image` and `build` replaced `COPY` and `RUN`. Those stay inside the Dockerfile.
- `ports:` replaces `-p`, and `volumes:` replaces `-v`.
- Container names come from the folder plus the service name, for example `visit-counter-app-1`.

## Commands
- `sudo docker compose up -d --build`: build the `app` image, start everything in the background.
- `sudo docker compose ps`: the project's containers.
- `sudo docker compose down` stops and removes the containers (and the network). `down -v` also removes the volumes, and the data with them.
  - **Check:** `-v` here means volumes, not verbose. It's the same `-v` as in `docker run -v`.

## Data survives (the experiment)
- 3 visits, then `down`, then `up`: the count was 4, because the volume `visit-counter_redis-data` survived.
- `down -v`, then `up`: the count was 1, because the volume was deleted and recreated empty.

## The app listens on `0.0.0.0`
- So it can talk to other devices on the network that aren't the host machine.
  - **Check:** more precisely, inside a container `127.0.0.1` means that container's own loopback. With it, neither other containers nor my laptop (through `-p`) could reach the app. `0.0.0.0` lets connections in from outside the container itself.

## The Dockerfile and the cache
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
CMD ["python", "app.py"]
```
- `COPY requirements.txt .`: `COPY` takes from and to. The `.` is the destination, meaning "here", the `WORKDIR` (`/app`). It copies only that one file. (`COPY . .` would copy everything.)
- `requirements.txt` is copied on its own, first, so the `pip install` layer depends only on it. Changing `app.py` keeps `pip install` cached.
- Docker checks the checksum. When the files are different, it reruns from that `COPY` (or build step) onwards.
  - **Check:** for each line Docker asks "same as last time?". A `COPY` compares file checksums, and a `RUN` compares the command text and the layer before it. At the first line that changed, the cache breaks, and that line and everything after it are rebuilt.

## The slow stop (bug)
- Symptom: `docker compose down` took 10.2 s for `app` but 0.1 s for Redis.
- Cause: `app` was PID 1 in its container, and PID 1 ignores `SIGTERM` unless it has a handler for it. Docker sends `SIGTERM`, waits 10 s, then sends `SIGKILL`.
- Fix: `init: true` in `compose.yaml` makes a tiny init program PID 1.
  - **Check:** the init program (Docker uses `tini`) receives `SIGTERM` and forwards it to my app. My app is no longer PID 1, so it stops normally. After the fix: 0.2 s.
- The `up -d` after the change still took 10.6 s, because Compose first stopped the old container, the one without `init`.

## Teach-back
- I learned how networks in Docker work: they're a LAN for containers, and containers find each other by name because of the DNS service. The names come from the service names, and the network is named after the folder and made by default, however many services there are.
- I learned how to write a YAML file: `build` is the build command, `ports` is `-p`, `volumes` is `-v`, and `image` is the image name we'd use with `docker run`. In the experiment, the data stayed in the volume, and `compose down` alone doesn't delete the volume, so you need `-v` to delete it. Otherwise all the information from that run stays.
- I learned that the app runs as PID 1 in the container, so it ignored `SIGTERM` and Docker had to use `SIGKILL`. We fixed it with `init: true`.
  - **Check:** `init: true` doesn't make the app handle `SIGTERM`. It puts a tiny init in as PID 1, which forwards the signal to the app.
