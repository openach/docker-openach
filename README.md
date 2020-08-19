# docker-openach
Docker with OpenACH, running on an Ubuntu 18.04 LTS image with Apache, PHP 7.3, and and SQLite

This repository contains **Dockerfile** of [OpenACH](http://openach.com/) for [Docker](https://www.docker.com/)'s [automated build](https://registry.hub.docker.com/u/openach/openach/) published to the public [Docker Hub Registry](https://registry.hub.docker.com/).

### Base Docker Image

* [dockerfile/ubuntu](http://dockerfile.github.io/#/ubuntu) 18.04 LTS


### Installation


#### Prerequisites

1. Install [Docker](https://docs.docker.com/machine/install-machine/).

2. Install [Docker Compose](https://docs.docker.com/compose/install/)

#### Clone the Repository

Clone this repository:
```
    git clone https://github.com/openach/docker-openach.git
    cd docker-openach
```
#### SSL Certificates

##### CA-Signed Certificate
If you already have a CA-signed SSL certificate you wish to use on your installation, copy the key and certificate files to ssl/openach/.  Then remove the existing symlinks and re-link your certificates to the proper names:

```
   rm ssl/openach/openach.crt ssl/openach/openach.key
   ln -s ssl/openach/<your_ssl.crt> ssl/openach/openach.crt
   ln -s ssl/openach/<your_ssl.key> ssl/openach/openach.key
```

##### Self-Signed Certificate
We have provided a script to simplify setting up a self-signed SSL certificate.  Note that the FQDN of your server should be whatever you are using to connect to OpenACH. Typically this will just be localhost, but if you have set up your DNS or hosts file to use something different, you can certainly use that instead.
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

#### Optionally Build the Image
The latest OpenACH code base is automatically built into a Docker image on https://hub.docker.com.  For most purposes, you can simply use that image.  If you have local modifications to the Dockerfile, you may want to build your own image.

The docker-compose.yml file looks for the openach/openach image, so you can either build with that label, or build with your own and modify docker-compose.yml accordingly.

Most people can skip this step and proceed directly to **Usage**

```
    sudo docker build -t openach/openach .
```

This can take a while but should eventually return a command prompt. It's done when it says "Successfully built {hash}"

### Usage
```
    docker-compose up -d
```

The first time the image is run, the startup script will initialize both config/db.php and config/security.php, and install a default database in runtime/db/openach.db, assuming they don't already exist.

#### Access the OpenACH CLI:
```
    docker exec -it dockeropenach_web_1 /bin/bash
```
Note that you will want to use the CLI to set up a user account before you go much further.  See the [OpenACH CLI Documentation](https://openach.com/books/openach-cli-documentation/openach-cli-documentation) for more information.

#### Access the web interface:
Note that the web interface is primarily for trouble-shooting and basic admin functions.  It is provided for convenience, but will be deprecated in future releases.   As such, most administrative tasks should be done via the OpenACH CLI.

To access the web interface, open your web browser and point to http://localhost/ or https://localhost/

Most importantly, the API is accessible via the web.  Assuming you are using the default _localhost_ hostname, the API would then be located at: http://localhost/api/ or https://localhost/api/

#### Using the REST API:
The simplest way to get started with the API is by checking out our API docs on Postman: https://documenter.getpostman.com/view/2849701/openach-api/7157b8e

And you can try out the API using our Postman collection:  https://www.getpostman.com/collections/ff17ba32b6d0ebd1b378

### Production Notes
When you first run "docker-compose up -d", a new encryption key will be generated for your data, and saved as config/security.php.  An empty SQLite database will be created as runtime/db/openach.db, and a database config file saved as config/db.php.  Subsequently, whenever you run docker-compose from the openach-docker folder, your OpenACH install will use these configs and database.  If you are using the Docker image as a production environment, you will want to regularly back up config/ and runtime/db/, as your production data depends on these two folders - one for the encryption keys and the other for the database itself.

#### Migrating Data
To migrate your config and data to a new host, simply pull a fresh copy of the openach/docker-openach project from GitHub, build the image (if it hasn't been previously built on your server), and copy the config/ and runtime/ folders from your other installation.

#### Security
Your Docker container exposes both port 80 (http) and port 443 (https).  Be sure to set up appropriate firewall rules on your host machine to protect traffic to these ports.  Also, be aware that the config/security.php file contains your encryption key for your data - protect it and your machine accordingly.
