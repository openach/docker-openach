FROM ubuntu:14.04
MAINTAINER Steven Brendtro <info@openach.com>

# OpenACH Release (release tag from https://github.com/openach/openach/)
# Update this to the version of OpenACH that should be installed
ARG OPENACH_RELEASE=1.9

# Copy our ARG into an ENV var so it persists
ENV OPENACH_RELEASE ${OPENACH_RELEASE}

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
        php5 \
        php5-cli \
        php5-mcrypt \
        php5-sqlite \
        php5-pgsql \
        php5-curl \
        php5-gmp \
        build-essential \
        php5-dev \
        php-pear && \
    apt-get clean && \
    pecl install doublemetaphone && \
    echo 'extension=doublemetaphone.so' > /etc/php5/mods-available/doublemetaphone.ini && \
    php5enmod doublemetaphone mcrypt sqlite pgsql curl && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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
ADD setup.d/yii-1.1.16.bca042.tar.gz /home/www/
RUN ln -s yii-1.1.16.bca042/ yii

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
RUN a2enmod alias dir mime php5 rewrite status && \
    a2ensite 000-default
RUN a2enmod ssl && \
    a2ensite default-ssl

# Expose HTTP and HTTPS
EXPOSE 80 443

# Add a start management script
ADD setup.d/openach-start /openach-start

# By default, run our start scripts
CMD ["bash", "/openach-start"]

