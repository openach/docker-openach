# docker-openach
Docker with OpenACH, running Apache, mod_php, and SQLite

This repository contains **Dockerfile** of [OpenACH](http://openach.com/) for [Docker](https://www.docker.com/)'s [automated build](https://registry.hub.docker.com/u/openach/openach/) published to the public [Docker Hub Registry](https://registry.hub.docker.com/).

### Base Docker Image

* [dockerfile/ubuntu](http://dockerfile.github.io/#/ubuntu)


### Installation


#### Build Your Own Docker Image

##### Prerequisites

1. Install [Docker](https://docs.docker.com/machine/install-machine/).

2. Install [Docker Compose](https://docs.docker.com/compose/install/)

##### Setup and Install

Clone this repository:
```
    git clone https://github.com/openach/docker-openach.git
    cd docker-openach
```

Set up a self-signed SSL certificate.  Note that the FQDN of your server should be whatever you are using to connect to OpenACH. Typically this will just be localhost, but if you have set up your DNS or hosts file to use something different, you can certainly use that instead.
```
   # ./makecerts.sh 
   Generating a 4086 bit RSA private key
   ....++
   .................................++
   writing new private key to './ssl/openach-self-signed.key'
   -----
   You are about to be asked to enter information that will be incorporated
   into your certificate request.
   What you are about to enter is what is called a Distinguished Name or a DN.
   There are quite a few fields but you can leave some blank
   For some fields there will be a default value,
   If you enter '.', the field will be left blank.
   -----
   Country Name (2 letter code) [AU]:US
   State or Province Name (full name) [Some-State]:New York
   Locality Name (eg, city) []:New York
   Organization Name (eg, company) [Internet Widgits Pty Ltd]:Your Company, Inc.
   Organizational Unit Name (eg, section) []:
   Common Name (e.g. server FQDN or YOUR name) []:localhost
   Email Address []:info@yourcompany.com
```

And then build it:
```
    sudo docker build -t openach/openach .
```

This can take a while but should eventually return a command prompt. It's done when it says "Successfully built {hash}"

### Usage
```
    docker-compose up -d
```

#### Access the OpenACH CLI:
```
    docker exec -it dockeropenach_web_1 /bin/bash
```
Note that you will want to use the CLI to set up a user account before you go much further.  See the [OpenACH CLI Documentation](http://openach.com/books/openach-cli-documentation/openach-cli-documentation) for more information.

#### Access the web interface:
Open your web browser and point to http://localhost/ or https://localhost/

The API would then be located at: http://localhost/api/ or https://localhost/api/

### Production Notes
When you first run "docker-compose up -d", a new encryption key will be generated for your data, and saved as config/security.php.  An empty SQ
Lite database will be created as runtime/db/openach.db, and a database config file saved as config/db.php.  Subsequently, whenever you run dock
er-compose from the openach-docker folder, your OpenACH install will use these configs and database.  If you are using the Docker image as a pr
oduction environment, you will want to regularly back up config/ and runtime/db/, as your production data depends on these two folders - one fo
r the encryption keys and the other for the database itself.

#### Migrating Data
To migrate your config and data to a new host, simply pull a fresh copy of the openach/docker-openach project from GitHub, build the image (if it hasn't been previously built on your server), and copy the config/ and runtime/ folders from your other installation.

#### Security
Your Docker container exposes both port 80 (http) and port 443 (https).  Be sure to set up appropriate firewall rules on your host machine to protect traffic to these ports.  Also, be aware that the config/security.php file contains your encryption key for your data - protect it and your machine accordingly.
