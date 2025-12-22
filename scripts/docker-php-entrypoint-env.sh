#!/usr/bin/env sh
set -e

# Generate application.ini based on environment variables
cat > /usr/local/etc/php/conf.d/application.ini <<EOF
date.timezone = ${TIMEZONE:-Europe/Rome}
error_log = ${PHP_ERROR_LOG:-/tmp/php_errors.log}
log_errors = ${PHP_LOG_ENABLED:-1}
max_execution_time = ${PHP_MAX_EXECUTION_TIME:-60}
memory_limit = ${PHP_MEMORY_LIMIT:-512M}
post_max_size = ${PHP_POST_MAX_SIZE:-20M}
sendmail_path = ${PHP_SENDMAIL:-/usr/local/sendmail}
upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE:-20M}
EOF

# Generate opcache.ini based on environment variables
cat > /usr/local/etc/php/conf.d/opcache.ini <<EOF
opcache.enable = ${OPCACHE_ENABLED:-1}
opcache.memory_consumption = ${OPCACHE_MEMORY_CONSUMPTION:-128}
opcache.interned_strings_buffer = ${OPCACHE_INTERNED_STRINGS_BUFFER:-8}
opcache.max_accelerated_files = ${OPCACHE_MAX_ACCELERATED_FILES:-4000}
opcache.revalidate_freq = ${OPCACHE_REVALIDATE_FREQ:-60}
opcache.fast_shutdown = ${OPCACHE_FAST_SHUTDOWN:-1}
EOF

# Call the original entrypoint script
exec docker-php-entrypoint "$@"
