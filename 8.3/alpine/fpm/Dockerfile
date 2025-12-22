ARG PHP_VERSION=8.3.29

FROM composer:2.9.2 AS composer
FROM php:${PHP_VERSION}-fpm-alpine3.23

LABEL com.bmeme.project.family='PHP Docker Image' \
    com.bmeme.project.version="${PHP_VERSION}-fpm-alpine" \
    com.bmeme.maintainer.1='Daniele Piaggesi <daniele.piaggesi@bmeme.com>' \
    com.bmeme.maintainer.2='Roberto Mariani <roberto.mariani@bmeme.com>' \
    com.bmeme.refreshedat='2025-12-22'

# Variables
ENV COMPOSER_HOME=/var/www/.composer \
    TIMEZONE=Europe/Rome

# PHP extensions variables
ENV IGBINARY_VERSION=3.2.16 \
    MCRYPT_VERSION=1.0.9 \
    OAUTH_VERSION=2.0.10 \
    REDIS_VERSION=6.3.0

# PHP environment variables
ENV PHP_MEMORY_LIMIT=512M \
    PHP_MAX_EXECUTION_TIME=60 \
    PHP_LOG_ENABLED=1 \
    PHP_ERROR_LOG=/tmp/php_errors.log \
    PHP_UPLOAD_MAX_FILESIZE=20M \
    PHP_POST_MAX_SIZE=20M \
    PHP_SENDMAIL=/usr/sbin/sendmail

# OPCACHE environment variables
ENV OPCACHE_ENABLED=1 \
    OPCACHE_MEMORY_CONSUMPTION=128 \
    OPCACHE_INTERNED_STRINGS_BUFFER=8 \
    OPCACHE_MAX_ACCELERATED_FILES=4000 \
    OPCACHE_REVALIDATE_FREQ=60 \
    OPCACHE_FAST_SHUTDOWN=1

ENV PERSISTENT_PROGRAMS="\
    gnupg \
    git \
    mysql-client \
    patch \
    python3 \
    tzdata \
    unzip \
    vim \
    zip"

WORKDIR /var/www/html

# install Composer
COPY --from=composer /usr/bin/composer /usr/bin/composer
# install the entrypoint script for env generation
COPY scripts/docker-php-entrypoint-env.sh /usr/local/bin/docker-php-entrypoint-env.sh

# install the PHP extensions we need
RUN --mount=type=cache,target=/tmp/pear,sharing=locked --mount=type=cache,target=/root/.cache/composer set -eux; \
    apk add --no-cache \
    ${PERSISTENT_PROGRAMS} \
    freetype \
    libjpeg-turbo \
    libpng \
    icu-libs \
    libmcrypt \
    pcre2 \
    libpq \
    libzip \
    libwebp \
    ; \
    apk add --no-cache --virtual .build-deps \
    ${PHPIZE_DEPS} \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    icu-dev \
    libmcrypt-dev \
    pcre2-dev \
    libpq-dev \
    libzip-dev \
    libwebp-dev \
    ; \
    \
    pecl install \
    mcrypt-${MCRYPT_VERSION} \
    igbinary-${IGBINARY_VERSION} \
    oauth-${OAUTH_VERSION} \
    ; \
    \
    # See https://github.com/phpredis/phpredis/issues/1176#issuecomment-558787347
    pecl bundle --destination=/usr/src/php/ext redis-${REDIS_VERSION}; \
    \
    docker-php-ext-configure gd \
    --with-freetype=/usr \
    --with-jpeg=/usr \
    --with-webp=/usr \
    ; \
    docker-php-ext-configure intl; \
    docker-php-ext-configure zip; \
    docker-php-ext-configure redis \
    --enable-redis-igbinary \
    --enable-redis-lzf \
    ; \
    \
    docker-php-ext-enable \
    mcrypt \
    igbinary \
    oauth \
    ; \
    docker-php-ext-install -j "$(nproc)" \
    bcmath \
    gd \
    intl \
    opcache \
    pdo_mysql \
    pdo_pgsql \
    redis \
    # due to error: invalid application of 'sizeof' to incomplete type 'struct cmsgcred'
    # sockets \
    zip \
    ; \
    \
    docker-php-source delete; \
    apk del .build-deps

RUN set -eux; \
    # set localtime and timezone
    ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime; \
    echo "${TIMEZONE}" > /etc/timezone; \
    \
    # make the entrypoint script executable
    chmod +x /usr/local/bin/docker-php-entrypoint-env.sh; \
    \
    # configure composer home directory
    mkdir -p ${COMPOSER_HOME}; \
    chown -R www-data:www-data ${COMPOSER_HOME}; \
    \
    # inject index.php
    echo "<?php phpinfo();" > /var/www/html/index.php

ENTRYPOINT ["docker-php-entrypoint-env.sh"]
CMD ["php-fpm"]
