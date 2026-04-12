FROM php:8.5-cli

# Extensões PHP via install-php-extensions (IPE)
COPY --from=ghcr.io/mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions \
    curl gd mbstring zip pdo_mysql pdo_pgsql intl \
    imagick bcmath sqlite3 readline opcache xdebug

# Symfony CLI
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash \
    && apt-get install -y symfony-cli

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app
