# DevContainer

## 1. Build das imagens PHP

```bash
docker build -t php:8.2-dev ./php/8.2
docker build -t php:8.3-dev ./php/8.3
```

## 2. Subir os bancos

```bash
cd infra && docker compose up -d
```

## 3. Configurar o PATH

Adicione no `~/.bashrc` ou `~/.zshrc`:

```bash
export PATH="$HOME/DevContainer/bin:$PATH"
```

## 4. Usar PHP e Composer

Execute dentro do diretório do projeto:

```bash
php83 artisan migrate
composer83 install

php82 artisan migrate
composer82 install
```

## Conexões

| Banco       | Host (container) | Porta (host) | Usuário    | Senha      |
|-------------|------------------|--------------|------------|------------|
| MySQL 8.4   | `c-pm-mysql84`     | `33061`      | `root`     | `password` |
| MariaDB 11.4| `c-bd-mariadb114`  | `33062`      | `root`     | `password` |
| PostgreSQL  | `c-pe-postgres18`  | `54321`      | `postgres` | `password` |