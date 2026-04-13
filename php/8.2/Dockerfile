FROM php:8.2-cli

# Instalar unzip para descompactação eficiente de arquivos ZIP do Composer
RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/*

# Extensões PHP via install-php-extensions (IPE)
COPY --from=ghcr.io/mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions \
    curl gd mbstring zip pdo_mysql pdo_pgsql intl \
    imagick bcmath sqlite3 readline opcache xdebug \
    ftp mongodb redis sodium

# Symfony CLI
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash \
    && apt-get install -y symfony-cli

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app