# docker-openach
Docker with OpenACH, running Apache, mod_php, and SQLite

This repository contains **Dockerfile** of [OpenACH](http://openach.com/) for [Docker](https://www.docker.com/)'s [automated build](https://registry.hub.docker.com/u/openach/openach/) published to the public [Docker Hub Registry](https://registry.hub.docker.com/).

### Base Docker Image

* [dockerfile/ubuntu](http://dockerfile.github.io/#/ubuntu)


### Installation


#### Using Prebuilt Docker Image 

1. Install [Docker](https://www.docker.com/).

2. Download [automated build](https://registry.hub.docker.com/u/openach/openach/) from public [Docker Hub Registry](https://registry.hub.docker.com/): `docker pull openach/openach`


#### Build Your Own Docker Image
Clone this repository:
```
    git clone https://github.com/openach/docker-openach.git
    cd docker-openach
```
And then build it:
```
    sudo docker build -t <yourname>/openach .
```

This can take a while but should eventually return a command prompt. It's done when it says "Successfully built {hash}"


### Usage
#### If you used the prebuilt image:
```
    docker run -d -p 80:80 -p 443:443 openach/openach

#### If you built your own:
```
    docker run -p 80:80 -p 443:443 -d <yourname>/openach

#### Access the OpenACH CLI:
```
    docker exec -it <YOUR_CONTAINER_ID_OR_NAME> /bin/bash

Note that you will want to use the CLI to set up a user account before you go much further.  See the [OpenACH CLI Documentation](http://openach.com/books/openach-cli-documentation/openach-cli-documentation) for more information.

#### Access the web interface:
Open your web browser and point to http://localhost/

The API would then be located at: http://localhost/api/
