# visit-counter

* a containerized flask app and redis working together to count the number of visits.

## Contents

* Flask application that counts the visits to the website
* Redis application that stores the count of the visits in persistent storage
* Docker compose used to containerize the application
* Github actions used for CI/CD pipeline
* GHCR store the image of the system in a registry

## Run it locally

* prerequisites to run this are:
	* docker and docker compose
	* git clone the repo
	```
	git clone https://github.com/Rayyan98Dev/devops-journey.git
	```
	* cd into the repo execute these from /devops-journey/projects/visit-counter/
	* .env file 
	```
	printf 'HOST_PORT=8000\nREDIS_HOST=redis\n' > .env
	```
	* secrets folder with a dummy api_key.txt
	```
	mkdir secrets
	echo "dummy-key" > secrets/api_key.txt
	```
	
* to run it locally use 
	```
	sudo docker compose up -d --build
	```
* url to visit site and count that visit is 
```
curl http://localhost:8000/
```
* expected output
```
Hello from Catto! This page has been visited 1 times.
```
* to stop the process to keep the count
```
sudo docker compose down
```

* to stop the process and delete the count
```
sudo docker compose down -v
```


## CI/CD

* On a PR run it will run to if simple-job passes this has the pytest and then it will do build image and trivy scan, skip pushing the image. When both jobs pass then you will be allowed to merge.
	We build the image but not push it as we dont want to keep pushing images for every pr that might not make any changes or push a bad image
* On a merge to main  it will run to if simple-job passes this has the pytest and then it will do build image and trivy scan and then push the image to GHCR tagged with the commit SHA when the scan passes.

## Security decisions

The rule behind all of these: nothing gets more access than it needs.

* rootful Docker (`sudo docker`), the industry standard, with each container hardened instead of going rootless
* the app runs as a non-root user (`appuser`, uid 10001)
* `cap_drop: ALL` on both containers. Redis can no longer switch user by itself, so `user: redis` is set in `compose.yaml`
* `no-new-privileges`, so nothing inside can gain more rights later
* read-only filesystem, with a `tmpfs` mounted `noexec` for the few files that must be written
* memory and pid limits, so one container can't starve the laptop
* healthchecks, and `init: true` so the app stops cleanly on `SIGTERM`
* port published on `127.0.0.1` only (Docker's own firewall rules skip firewalld)
* the API key is a Compose secret, not an environment variable
* CI: Trivy scans the image and blocks the push on HIGH/CRITICAL vulnerabilities that have a fix
* CI: actions pinned by full commit SHA, and the image tagged with the commit SHA so every image traces back to its code
* CI: only `packages: write` permission, and the package only accepts writes from this repo
* `main` is protected: changes go through a PR with required checks

## What I learned

* Security comes first now. I learned how privileges work in containers, and how attackers use privilege escalation and running code from writable folders. That's why each setting above exists, and I find it really interesting.
* Before this I only used CI/CD pipelines that were already built inside large systems. Building one myself showed me what a pipeline is for: what it can check and what it can stop before it reaches `main` or the registry. Next I want to understand its limits, and what it can't catch.
* I'm much more comfortable in Bash and the Linux terminal, and I see why people like it. The more commands I learn, the more I can automate myself with my own scripts.
