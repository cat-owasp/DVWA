FROM docker.io/library/php:8-apache

LABEL org.opencontainers.image.source=https://github.com/digininja/DVWA
LABEL org.opencontainers.image.description="DVWA pre-built image."
LABEL org.opencontainers.image.licenses="gpl-3.0"

WORKDIR /var/www/html

# https://www.php.net/manual/en/image.installation.php
RUN apt-get update \
 && export DEBIAN_FRONTEND=noninteractive \
 && apt-get install -y zlib1g-dev libpng-dev libjpeg-dev libfreetype6-dev iputils-ping git zip unzip 7zip  \
 && apt-get clean -y && rm -rf /var/lib/apt/lists/* \
 && docker-php-ext-configure gd --with-jpeg --with-freetype \
 && a2enmod rewrite \
 # Use pdo_sqlite instead of pdo_mysql if you want to use sqlite
 && docker-php-ext-install gd mysqli pdo pdo_mysql

# The File Inclusion labs (vulnerabilities/fi) need the http:// wrapper to work
# inside include(), i.e. RFI. php:8-apache ships no php.ini at all, so
# allow_url_include keeps its built-in default of Off and setup.php flags it red.
# The directive is deprecated since PHP 7.4 but still honoured in 8.x; the startup
# deprecation notice goes to the Apache error log, not into the served pages.
# allow_url_fopen is already On by default and needs nothing.
RUN echo "allow_url_include = On" > /usr/local/etc/php/conf.d/dvwa-rfi.ini

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
COPY --chown=www-data:www-data . .
COPY --chown=www-data:www-data config/config.inc.php.dist config/config.inc.php

# This is configuring the stuff for the API
RUN cd /var/www/html/vulnerabilities/api \
 && composer install \
