FROM sickp/alpine-nginx:1.13.8

# Using repo packages instead of compiling from scratch
ADD https://php.codecasts.rocks/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub
RUN echo "@php http://php.codecasts.rocks/v3.7/php-7.1" >> /etc/apk/repositories
RUN apk add --no-cache --update \
    php7@php \
    php7-common@php \
    php7-ctype@php \
    php7-dom@php \
    php7-curl@php \
    php7-fpm@php \
    php7-gd@php \
    php7-iconv@php \
    php7-intl@php \
    php7-json@php \
    php7-mbstring@php \
    php7-mcrypt@php \
    php7-mysqlnd@php \
    php7-opcache@php \
    php7-openssl@php \
    php7-pdo@php \
    php7-phar@php \
    php7-session@php \
    php7-xml@php \
    php7-zip@php \
    php7-zlib@php \
    php7-pdo_mysql@php \
    php7-pcntl@php \
    php7-posix@php \
    bash git grep dcron tzdata \
    supervisor

# Configure time
RUN echo "America/Sao_Paulo" > /etc/timezone && \
    cp /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    apk del tzdata && \
    rm /var/cache/apk/*

# CRON SETUP
COPY docker/cron/crontab /var/spool/cron/crontabs/root
RUN chmod -R 0644 /var/spool/cron/crontabs

# forward request and error logs to docker log collector
RUN ln -sf /dev/stderr /var/log/php7/error.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

RUN mkdir -p /var/www/html && \
    mkdir -p /usr/share/nginx/cache && \
    mkdir -p /var/cache/nginx && \
    mkdir -p /var/lib/nginx && \
    mkdir -p /etc/nginx/ssl && \
    chown -R nginx:nginx /etc/nginx/ssl /usr/share/nginx/cache /var/cache/nginx /var/lib/nginx/ && \
    ln -s /usr/bin/php7 /usr/bin/php && \
    openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048

COPY _SSL/dev.crt /etc/nginx/ssl/dev.crt
COPY _SSL/dev.key /etc/nginx/ssl/dev.key
COPY docker/conf/php-fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY docker/conf/supervisord.conf /etc/supervisor/supervisord.conf
COPY docker/conf/nginx.conf /etc/nginx/nginx.conf
COPY docker/conf/nginx-site.conf /etc/nginx/conf.d/default.conf
COPY docker/entrypoint.sh /sbin/entrypoint.sh

WORKDIR /var/www/html/

COPY ./ .

COPY --from=composer:1.5 /usr/bin/composer /usr/bin/composer

RUN chmod -R g+rw /var/www /usr/share/nginx/cache /var/cache/nginx /var/lib/nginx/ /etc/php7/php-fpm.d storage bootstrap/cache

CMD ["/sbin/entrypoint.sh"]