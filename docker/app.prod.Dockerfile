FROM php:8.2-cli-alpine AS build

WORKDIR /app

RUN apk add --no-cache \
        git unzip libzip-dev icu-dev oniguruma-dev zlib-dev autoconf gcc g++ make bash \
    && docker-php-ext-install intl pdo pdo_mysql zip opcache mbstring \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

COPY . /app

RUN composer update \
    && composer install --no-dev --optimize-autoloader --classmap-authoritative \
    && rm -rf /root/.composer/cache /tmp/* /var/cache/apk/* /var/tmp/*

FROM php:8.2-cli-alpine AS runtime

WORKDIR /app

COPY --from=build /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=build /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d
COPY --from=build /app /app

RUN apk add --no-cache icu-libs libzip zlib oniguruma bash \
    && rm -rf /tmp/* /var/cache/apk/* /var/tmp/*

ENV APP_ENV=prod \
    APP_DEBUG=0 \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=0

EXPOSE 8000

CMD ["php", "-S", "0.0.0.0:8000", "-t", "public"]
