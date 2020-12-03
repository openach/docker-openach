FROM ubuntu:20.04
MAINTAINER Steven Brendtro <info@openach.com>

# OpenACH Release (release tag from https://github.com/openach/openach/)
# Update this to the version of OpenACH that should be installed
ARG OPENACH_RELEASE=1.9.4

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
        unzip \
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
        php-pear \
        php-bcmath \
        php-zip \
        libapache2-mod-php \
        curl \
        vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Attempt to fix a pear warning
RUN mkdir -p /tmp/pear/cache

# Environment settings for composer
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    PATH=/root/.composer/vendor/bin:$PATH \
    TERM=linux \
    VERSION_PRESTISSIMO_PLUGIN=^0.3.10

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- \
        --version=1.10.16 \
        --filename=composer \
        --install-dir=/usr/local/bin \
    composer clear-cache

# Install composer plugins
RUN composer global require --optimize-autoloader \
        "hirak/prestissimo:${VERSION_PRESTISSIMO_PLUGIN}" && \
    composer global dumpautoload --optimize && \
    composer clear-cache

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

WORKDIR /home/www/openach/
RUN if [ -f composer.json ]; then  \
    composer install && composer clear-cache; \
fi

WORKDIR /home/www/

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
RUN a2enmod alias dir mime php7.4 rewrite status && \
    a2ensite 000-default
RUN a2enmod ssl && \
    a2ensite default-ssl

# Expose HTTP and HTTPS
EXPOSE 80 443

# Add a start management script
ADD setup.d/openach-start /openach-start

# By default, run our start scripts
CMD ["bash", "/openach-start"]

