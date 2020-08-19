FROM ubuntu:18.04
MAINTAINER Steven Brendtro <info@openach.com>

# OpenACH Release (release tag from https://github.com/openach/openach/)
# Update this to the version of OpenACH that should be installed
ARG OPENACH_RELEASE=1.9.3

# Copy our ARG into an ENV var so it persists
ENV OPENACH_RELEASE ${OPENACH_RELEASE}

# Ensure noninteractive mode
ARG DEBIAN_FRONTEND=noninteractive

# Turn off apt's cache in the container
RUN echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache

# Update and install system base packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
        git \
        subversion \
        jq \
        sqlite3 \
        apache2 \
        php \
        php-cli \
        php-sqlite3 \
        php-pgsql \
        php-curl \
        php-gmp \
        build-essential \
        php-dev \
        php-pear \
        php-bcmath \
        libapache2-mod-php \
        libmcrypt-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN pecl install channel://pecl.php.net/mcrypt-1.0.1 && \
    echo "extension=mcrypt.so" > /etc/php/7.2/mods-available/mcrypt.ini && \
    phpenmod mcrypt

# Initialize application
WORKDIR /home/www/

# Install OpenACH
RUN mkdir /home/www/openach/
RUN git clone https://github.com/openach/openach.git /home/www/openach/ && \
    cd /home/www/openach/ && \
    git pull origin master && \
    git checkout $OPENACH_RELEASE

# Clear out the distributed db and security files, as the startup script will deploy correct versions
RUN rm -f /home/www/openach/protected/config/db.php /home/www/openach/protected/config/security.php

# Install Yii 1.1
ADD setup.d/yii-1.1.22.bf1d26.tar.gz /home/www/
RUN ln -s yii-1.1.22.bf1d26/ yii

# Create some symlinks to simplify things when running the docker
RUN ln -s /home/www/openach/protected/config /config && \
    ln -s /home/www/openach/protected/runtime /runtime && \
    ln -s /home/www/openach/protected/openach /openach

# Make the temp folder for building ACH files
RUN mkdir /tmp/achfiles

RUN chown -R www-data:www-data /home/www/openach/protected/runtime/
RUN chown -R www-data:www-data /home/www/openach/assets/

RUN mkdir /etc/ssl/openach/
ADD ssl/openach/openach-self-signed.key.dist /etc/ssl/openach/openach-self-signed.key
ADD ssl/openach/openach-self-signed.crt.dist /etc/ssl/openach/openach-self-signed.crt

ADD setup.d/openach-init.php /openach-init.php

# Configure Apache
ADD setup.d/etc/apache2/sites-available/* /etc/apache2/sites-available/
RUN a2enmod alias dir mime php7.2 rewrite status && \
    a2ensite 000-default
RUN a2enmod ssl && \
    a2ensite default-ssl

# Expose HTTP and HTTPS
EXPOSE 80 443

# Add a start management script
ADD setup.d/openach-start /openach-start

# By default, run our start scripts
CMD ["bash", "/openach-start"]

