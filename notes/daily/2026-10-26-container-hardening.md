# Mon 26 Oct: Rootful vs rootless, and container hardening

*My own wording, spelling tidied. A **Check:** line is a correction we agreed on. Project: `projects/visit-counter/`.*

## Models
- The Docker client is the front-facing program. It takes my commands and sends them to `dockerd`, which is the program that actually does the work (builds images, runs containers). `dockerd` runs as root, so everything it creates is done and owned by root.
- A capability is a privileged action, like changing a file's owner, changing user, binding ports below 1024, or using raw sockets.
  - **Check:** more precisely, Linux splits root's powers into about 41 separate capabilities. Docker gives containers a default subset of 14 (`CapEff: 00000000a80425fb`).
- Rootless means `dockerd` no longer runs as root. A user namespace would be changing which user the program runs as.
  - **Check:** a user namespace is a separate ID table. IDs inside the container are mapped to different IDs on the host, so container-root (0) can be my own user (1000) on the laptop.

## Why `sudo docker run` gives root containers
- `sudo docker run` gives root containers because `dockerd`, the program that makes the containers, runs as root. `sudo` is only the key, because my terminal user isn't root and can't talk to `dockerd` otherwise.
  - **Check:** the "door" is `docker.sock`, owned by root and the `docker` group. Even in the `docker` group, containers would still run as root.
- I predicted my user would run `dockerd` and the container's `sleep`. Both were `root` (`root 1081 /usr/bin/dockerd`, `root 20612 sleep 300`). PID 1081 shows `dockerd` started at boot, long before my command.

## ID mapping
- `0 0 4294967295` maps root in the container to root on the host.
  - **Check:** it maps **every** ID to itself (0 to 0, 1 to 1, and so on, for about 4.3 billion IDs). It's an identity map, so there's no remapping at all.
- `catto-laptop:524288:65536` in `/etc/subuid` is the range of user IDs a non-root container can have.
  - **Check:** it means **65,536 IDs starting at 524288** (524288 to 589823). They're host IDs my user is allowed to use. Under rootless, container root becomes me (1000), and container UIDs 1 and up become `524288 + (UID − 1)`, so `appuser` 10001 would show as 534288. I first said "1024 and up", which is port language, not IDs.

| | Rootful (what I use) | Rootless |
|---|---|---|
| `dockerd` runs as | root | me |
| Container root is | host root | me (1000) |
| A container escape lands as | root | me |
| Costs | | ports below 1024 blocked, odd file ownership on bind mounts, slower networking, kind needs extra setup |

- `docker-ce-rootless-extras` is installed. `newuidmap` and `newgidmap` have `cap_setuid` / `cap_setgid` (the helpers that let a normal user set up the mapping).

## Decision: stay rootful, learn hardening
- We decided to go rootless because that is the industry standard, and to learn hardening and other techniques, since rootful is used on personal development machines.
  - **Check:** the other way round. We decided to **stay on rootful Docker**, because that's what CI runners and most workplaces use (production Kubernetes nodes mostly run the runtime as root too). Rootless is common on personal machines and shared hosts. The industry standard is **layers**: non-root images, dropped capabilities, read-only filesystems, limits, scanning, and in Kubernetes, pod security plus user namespaces (`hostUsers: false`, GA in 1.36). Rootless stays an optional parking-lot item.

## Hardening visit-counter
```yaml
services:
  app:
    build: .
    init: true
    ports:
      - "127.0.0.1:8000:8000"
    depends_on:
      - redis
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=16m
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    mem_limit: 256m
    pids_limit: 100
  redis:
    image: redis:7
    user: redis
    volumes:
      - redis-data:/data
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    mem_limit: 256m

volumes:
  redis-data:
```

| Setting | My words |
|---|---|
| `cap_drop: ALL` | drops all the privileges the container has |
| `read_only: true` | can be read, not written |
| `no-new-privileges` | prevents escalation |
| `mem_limit` / `pids_limit` | prevents attacks that fill memory or use up all the PIDs |
| `user: redis` | sets the owner to redis, so we don't have to grant the set-user privilege |

- **Check, `read_only`:** it makes the container's **own filesystem** (the image layers) read-only. Volumes and `tmpfs` keep their own permissions, so Redis still saves to `/data`. I predicted Redis couldn't save, but the count kept climbing (4, 5).
- **Check, `tmpfs` with `noexec,nosuid,size=16m`:** the one writable place can't run programs and can't fill memory.
- **Check, `no-new-privileges`:** specifically, a process can't gain privileges through setuid or setgid programs.
- **Check, `user: redis`:** it sets the **user the process runs as**, not a file owner.

### Results
- Before: root's `CapEff` was `00000000a80425fb` (Docker's default 14). After `cap_drop: ALL`: `0000000000000000`, even with `exec -u root`.
  - **Check:** I predicted "all capabilities" before hardening. It was a subset.
- `touch /app/x` gave `Read-only file system`, and `touch /tmp/ok` worked.
- The app still answered after dropping all capabilities.
  - **Check:** I predicted it wouldn't, assuming networking needs capabilities. Normal networking (connecting out, listening on ports 1024 and up) needs none. And `appuser` never had any capabilities: `cap_drop` matters when root shows up (`exec -u root`, or an escalation).

### Redis broke, then the fix
- Redis broke because it couldn't switch from root to the `redis` user: `setpriv: setresuid failed: Operation not permitted`, exit 127.
- Two fixes: give back the set-user privileges (`cap_add: [SETUID, SETGID]`), or set `user: redis` from the start. The second is safer, since it keeps privileges as low as possible (zero).
  - **Check:** writing files isn't a capability (that's ordinary permissions). `CHOWN` is only needed when the entrypoint fixes ownership of a brand-new volume. "Add back only what's needed" is the general pattern when an image needs something.
- While Redis was down, `curl` printed nothing: the app most likely hung until the 3-second timeout instead of failing fast.
  - **Check:** that's a reliability bug from my own checklist, no timeout on a network call. Fix later: `socket_connect_timeout` in the Redis client, plus a healthcheck.

## Hardening vs fixing the code
- Hardening protects against what an attacker can do if something goes wrong, which reduces the blast radius. Fixing the code prevents attackers from getting into that position in the first place.
- With injection still possible, an attacker would act as `appuser`: read and change Redis data, write to `/tmp`, connect out. Both are needed (defence in depth).

## Teach-back
- I learned about rootful and rootless, and how they affect what `dockerd` can and can't do.
- I learned that hardening reduces the capabilities of a block. Capabilities are actions that need privileged access.
  - **Check:** hardening is wider than capabilities, and it applies to a **container**: non-root user, dropped capabilities, read-only filesystem, `noexec` tmpfs, `no-new-privileges`, limits.
- I learned how to reduce capabilities to zero, that some actions like networking aren't capabilities and still work, and that this doesn't stop an attacker getting in, it just reduces the blast radius.

## Time log (estimated from message times; start the ClickUp timer next time)
- Recall quiz: 09:05 to 09:25 (with reworks).
- Block 1: 09:25 to 10:15.
- Break: 10:15 to 10:45.
- Block 2: 10:45 to 11:25.
- Wrap-up: 11:25 to 11:50.
