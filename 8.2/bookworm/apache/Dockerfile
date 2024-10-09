FROM composer:2.8.0 as composer
FROM php:8.2.24-apache-bookworm as ansible

ENV ANSIBLE_CORE_VERSION 2.17.4

RUN set -eux; \
	# install python 
	apt-get update && apt-get install -y --no-install-recommends python3 python3-distutils python3-pip; \
    \
	# install ansible
    pip install --no-cache-dir ansible-core==${ANSIBLE_CORE_VERSION} --break-system-packages

FROM php:8.2.24-apache-bookworm
LABEL   com.bmeme.project.family='PHP Docker Image' \
        com.bmeme.project.version='8.2.24-apache-bookworm' \
        com.bmeme.maintainer.1='Daniele Piaggesi <daniele.piaggesi@bmeme.com>' \
        com.bmeme.maintainer.2='Roberto Mariani <roberto.mariani@bmeme.com>' \
        com.bmeme.refreshedat='2024-10-04'

# Variables
ENV COMPOSER_HOME=/var/www/.composer \
    TIMEZONE=Europe/Rome

# PHP extensions variables
ENV IGBINARY_VERSION=3.2.16 \
    MCRYPT_VERSION=1.0.7 \
    OAUTH_VERSION=2.0.7 \
    REDIS_VERSION=6.0.2

# PHP environment variables
ENV PHP_MEMORY_LIMIT=512M \
    PHP_MAX_EXECUTION_TIME=60 \
    PHP_LOG_ENABLED=1 \
    PHP_ERROR_LOG=/tmp/php_errors.log \
    PHP_UPLOAD_MAX_FILESIZE=20M \
    PHP_POST_MAX_SIZE=20M \
    PHP_SENDMAIL=/usr/local/sendmail

# OPCACHE environment variables
ENV OPCACHE_ENABLED=1 \
    OPCACHE_MEMORY_CONSUMPTION=128 \
    OPCACHE_INTERNED_STRINGS_BUFFER=8 \
    OPCACHE_MAX_ACCELERATED_FILES=4000 \
    OPCACHE_REVALIDATE_FREQ=60 \
    OPCACHE_FAST_SHUTDOWN=1

ENV PERSISTENT_PROGRAMS \
	gnupg \
    git \
    default-mysql-client \
    patch \
    python3 \
    python3-distutils \
    tzdata \
    unzip \
    vim \
    zip

# install Composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

# install Ansible
COPY --from=ansible /usr/lib/python3.11/lib-dynload /usr/lib/python3.11/lib-dynload
COPY --from=ansible /usr/local/lib/python3.11/dist-packages /usr/local/lib/python3.11/dist-packages
COPY --from=ansible /usr/local/bin/ansible* /usr/local/bin/

# install the PHP extensions we need
RUN set -eux; \
	\
	if command -v a2enmod; then \
		a2enmod rewrite; \
	fi; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
        ${PHPIZE_DEPS} \
        ${PERSISTENT_PROGRAMS} \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpcre3-dev \
        libpng-dev \
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
	\
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
    # reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual ${savedAptMark}; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r realpath | xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
    apt-mark manual ${PERSISTENT_PROGRAMS}; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*; \
	\
    # remove php source
    docker-php-source delete

RUN set -eux; \
	# set localtime and timezone
	rm /etc/localtime; \
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