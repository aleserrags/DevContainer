FROM php:8.3-fpm

# Instalar dependências de sistema
RUN apt-get update && apt-get install -y \
    unzip \
    libmagickwand-dev \
    && rm -rf /var/lib/apt/lists/*

# Extensões PHP via install-php-extensions (IPE)
COPY --from=ghcr.io/mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions \
    gd zip pdo_mysql mysqli pdo_pgsql pgsql intl ftp \
    imagick-3.8.0 bcmath xdebug

# Symfony CLI
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash \
    && apt-get install -y symfony-cli

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app