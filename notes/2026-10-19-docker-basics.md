# Mon 19 Oct: Docker basics

*My own wording, spelling tidied. A **Check:** line is a correction we agreed on.*

## Models
- An image is really a snapshot of a filesystem plus the command to run it, and it never changes. Docker uses it to make containers. It describes the container's environment.
- A container is really a running process made from an image, with its own walls: its own view of the files, the network, and so on.
  - It lives only as long as its main process. `hello-world` printed its message and exited, so its container stopped.
  - Each container has its own thin writable layer on top of the shared image.
- The Docker daemon (`dockerd`) is really the service that does all the Docker work, and `docker` is only the client.
  - `dockerd` is a systemd service: `enabled`, `active (running)`. That's last week's systemd lesson in practice.
- Why bother: it runs the same everywhere (laptop, server, CI), there are no dependencies to set up, and it's easy to throw away.

## Why `docker` needs `sudo`
- The client talks to the daemon through a socket file, `/var/run/docker.sock`.
- `ls -l` showed `srw-rw----. 1 root docker`:
  - `s` = socket (like `d` = directory and `l` = symlink)
  - owner `root`: read and write; group `docker`: read and write; others: nothing
- `id` showed I'm in `catto-laptop`, `wheel` and `i2c`, but not `docker`, so I count as "others" and get `permission denied`.
- **Check:** for a socket, read and write is what lets you talk to the daemon. Execute doesn't come into it. The danger is that the daemon runs as root, so anyone allowed to talk to it (the `docker` group) can make it do anything root can, for example mount the whole disk into a container.
- Decision: keep `sudo` for now, and set up rootless Docker on Fri 23 Oct so containers can only touch my own files.
- If I ever join the group: `sudo usermod -aG docker $USER`. The `-a` (append) matters, because without it I'd lose my other groups, including `wheel`. Group changes only take effect after logging out and back in.

## Kernel
- Docker containers don't have their own kernel. They use the laptop's kernel.
- My answer: nginx using Debian doesn't prove anything, since the kernel wouldn't change if I installed Debian on this laptop.
  - **Check:** it does prove it. Inside the container, `/etc/os-release` said Debian 13, but nginx's log said `OS: Linux 7.2.8-200.fc44`, which is my Fedora laptop's kernel. A Debian container with its own kernel would report a Debian kernel. Debian files plus a Fedora kernel means a shared kernel.

## Commands
- `docker run hello-world`: pulls the image from Docker Hub if it's missing, creates a container, runs it.
- `docker run -d --name web -p 127.0.0.1:8080:80 nginx`
  - `-d` (detached) runs it in the background and gives my terminal back.
  - `-p LAPTOP:CONTAINER` means laptop port 8080 goes to container port 80 (outside first, then inside).
  - **Check:** I first had the two numbers the wrong way round. `docker ps` showed `8080->80`.
- `docker ps` shows running containers. `docker ps -a` shows all of them, including stopped ones.
  - Every `docker run` makes a new container. `ps -a` showed three `hello-world` containers from three runs, each `Exited (0)`.
- `docker images` lists images. One `nginx` image (243 MB) was shared by every container.
- `docker logs web` shows the container's output.
- `docker exec -it web bash` gives a shell inside a running container (`-it` = interactive, with a terminal).
- `docker stop web` stops it (it still shows in `ps -a`). `docker rm -f web` stops and deletes it. `docker container prune -f` deletes all stopped containers but keeps the images.
- `docker run --rm ...` deletes the container automatically when it exits.

## The port-exposure gotcha
- The phone could reach nginx because Docker has its own firewall rules, which let traffic through before my `home` zone's rules ever check it.
- With `-p 8080:80`, `docker ps` showed `0.0.0.0:8080`, meaning every network connection. `firewall-cmd` didn't list 8080 anywhere.
- My fix: define which IP address can reach it.
  - **Check:** the IP in `-p` isn't a list of who may connect. It picks which of the laptop's own addresses the port listens on. `-p 127.0.0.1:8080:80` listens only on the laptop itself, so the phone got nothing. Limiting *who* can connect is the firewall's or the app's job (in the parking lot).

## Logs and getting inside
- The phone's visit didn't show in `docker logs`, because those logs were deleted along with the first container. Logs belong to each container.
- `172.17.0.1` in the log is Docker's internal bridge. Requests from my laptop reach the container through it.
- `304` is the HTTP status code "Not Modified": the browser already had the page cached.
- Inside the container, `hostname` was the first characters of the container's ID, and `whoami` was `root`. That matters because, with normal (rootful) Docker, that root has basically the same power as the computer's root.

## Changes disappear
- "hello from Catto" disappeared because the change was made in the container, not the image. When the container was removed and a new one started, it used what was in the image.
  - **Check:** the image wasn't removed, only the container. The edit lived in that container's own writable layer, and `rm` threw it away.
- Keeping data beyond a container's life is what volumes are for (coming this week).
- `container prune` reclaimed only 4 kB from four containers, which shows how thin a container's own layer is.

## Teach-back
- Today I learned about Docker. An image is a snapshot of the system that sets up its environment, and it's what a container is based on. A container is a program run from an image, with its own walls separating it from the rest of the system.
- I learned how to download an image, run it in the background with `-d`, and run it privately using the IP address in the ports flag, so only the laptop can reach it.
  - **Check:** that IP picks which of my laptop's addresses listens. It isn't a whitelist I can add visitors to.
- I learned how to get into a container with `sudo docker exec -it web bash` and make edits. I remember doing this at my old job to check things when the logs weren't enough. I also learned how to delete containers.
