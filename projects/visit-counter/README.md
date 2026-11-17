# visit-counter

* a containarized flask app and redis working together to count the number of visits.

## Contents

* Flask application that counts the visits to the website
* Redis application that store the count of the visits in persistent storage
* Docker compose used to containarizing the application
* Github actions used for CI/CD pipeline
* GHCR store the image of the system in a registry

## Run it locally

* prerequsites to run this are:
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

