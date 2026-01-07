ARG PHP_VERSION=8.3.29

FROM composer:2.9.2 AS composer
FROM php:${PHP_VERSION}-apache-trixie AS ansible

ENV DEBIAN_FRONTEND=noninteractive
ENV ANSIBLE_CORE_VERSION=2.19.4

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/root/.cache/pip set -eux; \
	# install python 
	apt-get update && apt-get install -y --no-install-recommends python3 python3-pip; \
	\
	# install ansible
	pip install --no-cache-dir ansible-core==${ANSIBLE_CORE_VERSION} --break-system-packages; \
	\
	rm -rf /var/lib/apt/lists/*

FROM php:${PHP_VERSION}-apache-trixie
ARG PHP_VERSION
ENV DEBIAN_FRONTEND=noninteractive
LABEL   com.bmeme.project.family='PHP Docker Image' \
	com.bmeme.project.version="${PHP_VERSION}-apache-trixie" \
	com.bmeme.maintainer.1='Daniele Piaggesi <daniele.piaggesi@bmeme.com>' \
	com.bmeme.maintainer.2='Roberto Mariani <roberto.mariani@bmeme.com>' \
	com.bmeme.refreshedat='2026-01-07'

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
	PHP_SENDMAIL=/usr/local/sendmail

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
	default-mysql-client \
	patch \
	python3 \
	python3-packaging \
	tzdata \
	unzip \
	vim \
	zip \
	curl \
	ca-certificates \
	libpng16-16 \
	libjpeg62-turbo \
	libwebp7 \
	libfreetype6 \
	libzip5 \
	libmcrypt4 \
	libicu76"

WORKDIR /var/www/html

# install Composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

# install Ansible
COPY --from=ansible /usr/lib/python3.13/lib-dynload /usr/lib/python3.13/lib-dynload
COPY --from=ansible /usr/local/lib/python3.13/dist-packages /usr/local/lib/python3.13/dist-packages
COPY --from=ansible /usr/local/bin/ansible* /usr/local/bin/
COPY scripts/docker-php-entrypoint-env.sh /usr/local/bin/docker-php-entrypoint-env.sh

# install the PHP extensions we need
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/tmp/pear --mount=type=cache,target=/root/.cache/composer set -eux; \
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
	libpcre2-dev \
	libpng-dev \
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
	docker-php-ext-configure redis \
	--enable-redis-igbinary \
	--enable-redis-lzf \
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
	zip \
	; \
	\
	# Enable extensions explicitly (safer/clearer)
	docker-php-ext-enable \
	mcrypt \
	igbinary \
	oauth \
	redis \
	; \
	\
	# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual ${savedAptMark}; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
	| awk '/=>/ && $3 ~ /^\// { print $3 }' \
	| sort -u \
	| xargs -r dpkg-query -S \
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
	ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime; \
	echo "${TIMEZONE}" > /etc/timezone; \
	\
	# configure composer home directory
	mkdir -p "$COMPOSER_HOME" && chown -R www-data:www-data "$COMPOSER_HOME"; \
	\
	# make docker-php-entrypoint-env.sh executable
	chmod +x /usr/local/bin/docker-php-entrypoint-env.sh; \
	\
	# inject index.php
	echo "<?php phpinfo();" > /var/www/html/index.php

ENTRYPOINT ["docker-php-entrypoint-env.sh"]
CMD ["apache2-foreground"]
