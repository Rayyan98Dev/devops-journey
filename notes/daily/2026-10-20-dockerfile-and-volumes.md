# Tue 20 Oct: Dockerfiles and volumes

*My own wording, spelling tidied. A **Check:** line is a correction we agreed on.*

## Models
- A Dockerfile is really a recipe that's used to build a Docker image. Each instruction adds one layer.
- A bind mount is really a link between a container folder (or file) and a host folder (or file). Changes made on the host's end are mirrored on the container's end, so it's useful for things that need a lot of changes from the host, like code.
- A volume is really a folder stored in Docker's own folders (`/var/lib/docker/volumes/<name>/_data`). It's persistent storage that's edited through the container, so it's better for things changed mainly by the container, like logs, databases and outputs.

## The Dockerfile (containerizing `ghuser.py`)
```dockerfile
FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir requests
COPY ghuser.py .
ENTRYPOINT ["python", "ghuser.py"]
```

| Line | My words |
|---|---|
| `FROM` | sets up the environment for the container (here, a small Debian with Python) |
| `WORKDIR` | makes the folder where the working data goes, like the code |
| `RUN` | runs commands while the image is being built, for example installing `requests` |
| `COPY` | copies the files or folders being dockerized into the image |
| `ENTRYPOINT` | what runs when the container starts: the actual program |

- `ENTRYPOINT` isn't a build step (`[1/4]` to `[4/4]` were `FROM`, `WORKDIR`, `RUN`, `COPY`), because it adds no files. It only records the start command in the image's settings.
- Build: `sudo docker build -t ghuser .` (`-t` names the image, `.` is the build context, the folder `COPY` can see).

### Look-alike: `RUN` vs `ENTRYPOINT` vs `CMD`
| | When it runs | Example |
|---|---|---|
| `RUN` | while the image is being built | `pip install requests` |
| `ENTRYPOINT` | when a container starts; words after the image name are added to the end | `python ghuser.py` + `octocat` |
| `CMD` | when a container starts, as the default command or default arguments | |

- My guess: `CMD` passes arguments from the Dockerfile instead of from the terminal, like `ENTRYPOINT` does.
  - **Check:** `CMD` sets the default command. Anything typed after the image name replaces it. Used together with `ENTRYPOINT`, `CMD` gives default arguments that the terminal can override.

## The layer cache
- Order matters, because once a line changes, it and every line after it are rebuilt. It doesn't make sense to rerun slow commands for things that barely change.
  - **Check:** the cache breaks at `COPY` because `ghuser.py` changed. So slow, rarely changing steps (`pip install`) go first, and my code goes last.
- The second build was much faster because `requests` wasn't reinstalled. It came from the cache (`CACHED [3/4]`).
  - **Check:** the numbers were 19.4 s down to 2.4 s, about 17 s faster. The `pip install` step alone was 10.4 s.
- The 1.9 s `load metadata` line is Docker asking Docker Hub whether the base image has a newer version, not a download.

## Running it
- `requests` was installed in the container using the `RUN` command.
  - **Check:** it was installed into the image, at build time, and saved as a layer. Every container made from the image already has it.
- `ENTRYPOINT` takes everything after the image name in `docker run` and passes it to the program as arguments: `docker run --rm ghuser octocat` runs `python ghuser.py octocat`, so `sys.argv[1]` is `octocat`.
- `echo $?` printed `2` because Docker passes its program's exit code to the terminal (no username means exit 2).
- `docker run --rm` deletes the container when it exits.

## Bind mount (nginx website)
- `-v ~/lab/site:/usr/share/nginx/html:ro`, with the order outside first, then inside (like `-p`).
- My edit showed up straight away, because the folder was linked with a bind mount, so changes on my laptop were mirrored in the container.
- After `rm -f` and a new container, the edit was still there, because the files live on my laptop.
- `:ro` means read-only, so the container can only read. Use it when the container shouldn't change the files. Trying to write gave `Read-only file system`.

## Named volume
- `sudo docker volume create notes`, then `-v notes:/data`. A name with no `/` means Docker uses a volume.
- `log.txt` had three entries because the file exists in a volume, outside the container, so every run wrote a new entry. It had three because I used `>>` (append), not `>`, which would have left only the latest entry.
- Each container was deleted (`--rm`), but the data survived.
- `docker volume inspect notes` showed `Mountpoint: /var/lib/docker/volumes/notes/_data` (owned by root, managed by Docker).
- The times said `09:39` while my clock said about 11:39, because containers use UTC unless a time zone is set.
- The first run had a typo (`cat /data/log.text`), but the `echo` still wrote, because `;` runs the next command whether or not the one before worked.

| | Bind mount | Named volume |
|---|---|---|
| Data lives | a folder I choose, in my home | managed by Docker, under `/var/lib/docker/volumes` |
| Edit directly? | yes | no, only through containers |
| Use for | code, config, a website I'm editing | an app's own data: logs, databases, outputs |

## Bug: "file with no instructions"
- My words: I forgot that Docker needed an actual Dockerfile with instructions, instead of making one by itself. The fix was to make the Dockerfile. I was a bit sleep-deprived, so mistakes happen.
  - **Check:** the Dockerfile existed, but on disk it was five empty lines, because the text never got saved in VSCodium. `cat -A Dockerfile` showed only `$` line ends. Fix: write it with a flush-left heredoc and check with `cat -A`.

## Teach-back
- Today I learned about making Dockerfiles: `FROM` sets the environment, `WORKDIR` makes the directory the files go in, `RUN` runs commands to install extra things, `COPY` copies the files I'm dockerizing, and `ENTRYPOINT` runs them.
  - **Check:** I first wrote "run runs them". `RUN` runs during the build, and `ENTRYPOINT` runs when a container starts.
- Docker can use mounts in two ways. A bind mount connects a host folder to the container, so changes I make are seen by the container, and it survives removal and restarts because it lives on my machine. A volume is a separate storage area that's edited through the container. It survives as well, but it's better for things like logs.
- (Missing from the teach-back: the layer cache. Rarely changing steps first, code last.)
