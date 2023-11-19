FROM composer:2.6.5 as composer
FROM php:8.1.25-fpm-alpine3.18
LABEL   com.bmeme.project.family='PHP Docker Image' \
        com.bmeme.project.version='8.1.25-fpm-alpine' \
        com.bmeme.maintainer.1='Daniele Piaggesi <daniele.piaggesi@bmeme.com>' \
        com.bmeme.maintainer.2='Roberto Mariani <roberto.mariani@bmeme.com>' \
        com.bmeme.refreshedat='2023-11-18'

# Variables
ENV COMPOSER_HOME=/var/www/.composer \
    TIMEZONE=Europe/Rome

# PHP extensions variables
ENV IGBINARY_VERSION=3.2.14 \
    MCRYPT_VERSION=1.0.6 \
    OAUTH_VERSION=2.0.7 \
    REDIS_VERSION=6.0.1

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

ENV PERSISTENT_PROGRAMS \
    git \
    mysql-client \
    patch \
    python3 \
    tzdata \
    unzip \
    vim \
    zip

# install Composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

# install the PHP extensions we need
RUN set -eux; \
    apk add --no-cache \
        ${PERSISTENT_PROGRAMS} \
        ${PHPIZE_DEPS} \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        icu-dev \
        libmcrypt-dev \
        pcre-dev \
        libpq-dev \
        libzip-dev \
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
	; \
    docker-php-ext-configure intl; \
	docker-php-ext-configure zip; \
	docker-php-ext-configure redis \
	    --enable-redis-igbinary \
	    --enable-redis-lzf \
	;\
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
    # remove php source
    docker-php-source delete; \
    apk del pcre-dev ${PHPIZE_DEPS}

RUN set -eux; \
	# set localtime and timezone
	rm -f /etc/localtime; \
	cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime; \
    echo "${TIMEZONE}" > /etc/timezone; \
    \
	# configure composer home directory
    mkdir ${COMPOSER_HOME}; \
    \
    # set application ini settings
    { \
        echo "date.timezone = ${TIMEZONE}"; \
        echo "error_log = ${PHP_ERROR_LOG}"; \
        echo "log_errors = ${PHP_LOG_ENABLED}"; \
        echo "max_execution_time = ${PHP_MAX_EXECUTION_TIME}"; \
        echo "memory_limit = ${PHP_MEMORY_LIMIT}"; \
        echo "post_max_size = ${PHP_POST_MAX_SIZE}"; \
        echo "sendmail_path = ${PHP_SENDMAIL}"; \
        echo "upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}"; \
	} > /usr/local/etc/php/conf.d/application.ini; \
	\
    # set opcache ini settings
    # see https://secure.php.net/manual/en/opcache.installation.php
    { \
		echo "opcache.enable = ${OPCACHE_ENABLED}"; \
		echo "opcache.memory_consumption = ${OPCACHE_MEMORY_CONSUMPTION}"; \
		echo "opcache.interned_strings_buffer = ${OPCACHE_INTERNED_STRINGS_BUFFER}"; \
		echo "opcache.max_accelerated_files = ${OPCACHE_MAX_ACCELERATED_FILES}"; \
		echo "opcache.revalidate_freq = ${OPCACHE_REVALIDATE_FREQ}"; \
		echo "opcache.fast_shutdown = ${OPCACHE_FAST_SHUTDOWN}"; \
	} > /usr/local/etc/php/conf.d/opcache.ini; \
	\
	# inject index.php
	echo "<?php phpinfo();" > /var/www/html/index.php
