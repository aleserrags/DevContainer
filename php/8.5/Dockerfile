FROM php:8.5-fpm

# Instalar unzip para descompactação eficiente de arquivos ZIP do Composer
RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/*

# Extensões PHP via install-php-extensions (IPE)
COPY --from=ghcr.io/mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions \
    gd zip pdo_mysql mysqli pdo_pgsql pgsql intl \
    imagick bcmath xdebug

# Symfony CLI
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash \
    && apt-get install -y symfony-cli

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app
