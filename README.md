[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity)
[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/)

PHP Packaged by Bmeme
=========

PHP docker images based on [official PHP repository](https://hub.docker.com/_/php/), currently used by Bmeme for its
development purposes, particularly suitable for Drupal or Symfony environments.

## What is contained in the images
* PHP, of course
* Some useful executables like:
  * `gnupg`
  * `git`
  * `patch`
  * `mysql-client`
  * `python3`
  * `vim`
  * `zip`
* The following php extensions
  * `bcmath`
  * `gd`
  * `intl`
  * `igbinary`
  * `mcrypt` only for 8.0 and older
  * `oauth`
  * `opcache`
  * `pdo_mysql`
  * `pdo_pgsql`
  * `phpredis`
  * `sockets` only 8.0 and older
  * `zip`
* Composer
* Ansible (used in Bmeme for all automation tasks, @see [here](https://github.com/bmeme/ansible-role-drupal), for example)

## Supported tags and respective `Dockerfile` links
- `8.3.9-apache-bookworm`, `8.3-apache-bookworm`, `latest` [Dockerfile](https://github.com/bmeme/docker-php/blob/main/8.3/bookworm/apache/Dockerfile)
- `8.3.9-fpm-alpine`, `8.3-fpm-alpine`, [Dockerfile](https://github.com/bmeme/docker-php/blob/main/8.3/alpine/fpm/Dockerfile) - **EXPERIMENTAL**
- `8.2.21-apache-bullseye`, `8.2-apache-bullseye` [Dockerfile](https://github.com/bmeme/docker-php/blob/main/8.2/bullseye/apache/Dockerfile)
- `8.2.21-fpm-alpine`, `8.2-fpm-alpine`, [Dockerfile](https://github.com/bmeme/docker-php/blob/main/8.2/alpine/fpm/Dockerfile) - **EXPERIMENTAL**
- `8.1.29-apache-bullseye`, `8.1-apache-bullseye` [Dockerfile](https://github.com/bmeme/docker-php/blob/main/8.1/bullseye/apache/Dockerfile)
- `8.1.29-fpm-alpine`, `8.1-fpm-alpine`, [Dockerfile](https://github.com/bmeme/docker-php/blob/main/8.1/alpine/fpm/Dockerfile) - **EXPERIMENTAL**

## Existent tags not more supported
- `8.1.14-apache-buster`, `8.1-apache-buster` [Dockerfile](https://github.com/bmeme/docker-php/blob/main/8.1/buster/apache/Dockerfile)
- `8.0.30-apache-bullseye`, `8.0-apache-bullseye` [Dockerfile](https://github.com/bmeme/docker-php/blob/main/8.0/bullseye/apache/Dockerfile)
- `8.0.30-apache-buster`, `8.0-apache-buster` [Dockerfile](https://github.com/bmeme/docker-php/blob/main/8.0/buster/apache/Dockerfile)
- `7.4.32-apache-bullseye`, `7.4-apache-bullseye`, [Dockerfile](https://github.com/bmeme/docker-php/blob/main/7.4/bullseye/apache/Dockerfile)
- `7.4.32-apache-buster`, `7.4-apache-buster`, [Dockerfile](https://github.com/bmeme/docker-php/blob/main/7.4/buster/apache/Dockerfile)
- `7.3.33-apache-buster`, `7.3-apache-buster`, [Dockerfile](https://github.com/bmeme/docker-php/blob/main/7.3/buster/apache/Dockerfile)
- `7.2.26-apache-buster`, `7.2-apache-buster`, [Dockerfile](https://github.com/bmeme/docker-php/blob/main/7.2/buster/apache/Dockerfile)

## How to use this image

### Manually
Starting your PHP environment is really simple:
```shell
$ docker run --name myphpcontainer -p 8080:80 -d bmeme/php:latest
```
Obviously you can change the local binding port matching your needs.

### Using a Dockerfile
```dockerfile
FROM bmeme/php:latest
COPY src/ /var/www/html/
```
Where `src/` is the directory containing all your PHP code.

Then, run the commands to build and run the Docker image:
```shell
$ docker build -t myphpimage:latest .
$ docker run -d --name myphpcontainer myphpimage:latest
```

### With a database image
```shell
$ docker run --name mydatabase -e ALLOW_EMPTY_PASSWORD=yes bitnami/mariadb:latest
$ docker run --name myapplication --link mydatabase -d bmeme/php:latest
```

## Custom environments

### PHP settings environments
| Variable Name | Description | Default |
|---------------|-------------|---------|
|`COMPOSER_HOME`|home directory where composer will store packages and configuration.|`/var/www/.composer` |
| `TIMEZONE`| Image Timezone | `Europe/Rome` |
| `PHP_MEMORY_LIMIT`| `memory_limit` PHP value | `512M`  |
| `PHP_MAX_EXECUTION_TIME`| `max_execution_time` PHP value | `60`    |
| `PHP_LOG_ENABLED`| `log_errors` PHP value. Boolean. | `1`     |
| `PHP_ERROR_LOG`| `error_log` PHP value. | `/tmp/php_errors.log` |
| `PHP_UPLOAD_MAX_FILESIZE`| `upload_max_filesize` PHP value. | `20M`   |
| `PHP_POST_MAX_SIZE`| `post_max_size` PHP value. | `20M`   |
| `PHP_SENDMAIL`| `sendmail_path` PHP value. | `/usr/local/sendmail` |

### OpCache config environments
| Variable Name  | Description | Default |
|----------------|-------------|---------|
| `OPCACHE_ENABLED`| `opcache.enable` PHP value | `1` |
| `OPCACHE_MEMORY_CONSUMPTION`| `opcache.memory_consumption` opcache config value | `128` |
| `OPCACHE_INTERNED_STRINGS_BUFFER`| `opcache.interned_strings_buffer` opcache config value | `8` |
| `OPCACHE_MAX_ACCELERATED_FILES`| `opcache.max_accelerated_files` opcache config value | `4000` |
| `OPCACHE_REVALIDATE_FREQ`| `opcache.revalidate_freq` opcache config value | `60` |
| `OPCACHE_FAST_SHUTDOWN`| `opcache.fast_shutdown` opcache config value | `1` |

For more infos about OpCache configuration @see https://www.php.net/manual/en/opcache.configuration.php

## Using `docker-compose`

```yaml
version: '3.1'
services:
  php:
    image: bmeme/php:latest
    ports:
      - 8080:80
    environment: # just as example
      - PHP_MEMORY_LIMIT=256M
      - OPCACHE_ENABLED=0
  mariadb:
    image: bitnami/mariadb:latest
    environment:
      - ALLOW_EMPTY_PASSWORD: yes
      - MARIADB_DATABASE: mydatabase
      - MARIADB_USER: myuser
      - MARIADB_PASSWORD: secret
```

## Credits
This project is a contribution of [Bmeme :: The Digital Factory](http://www.bmeme.com).
This library is actually maintained by [Daniele Piaggesi](https://github.com/g0blin79) and
[Roberto Mariani](https://github.com/jean-louis).
Any other contribution will be really appreciated.
