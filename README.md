# DevContainer

## 1. Build das imagens PHP

```bash
docker build -t php:8.2-dev ./php/8.2
docker build -t php:8.3-dev ./php/8.3
docker build -t php:8.5-dev ./php/8.5
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

## 4. Usar PHP, Composer e Symfony

Os scripts `cphp`, `ccomposer` e `csymfony` usam **PHP 8.5 por padrão**. Para usar outra versão, passe-a como primeiro argumento.

Execute dentro do diretório do projeto:

```bash
# PHP 8.5 (padrão)
cphp artisan migrate
cphp -r "echo PHP_VERSION;"

# PHP específico (primeiro argumento)
cphp 8.3 artisan migrate
cphp 8.2 -r "echo PHP_VERSION;"

# Composer
ccomposer install          # usa 8.5
ccomposer 8.3 install      # usa 8.3

# Symfony CLI
csymfony new meu-projeto   # usa 8.5
csymfony 8.2 new projeto   # usa 8.2
```

Versões disponíveis: `8.2`, `8.3`, `8.5`

## Conexões

| Banco       | Host (container) | Porta (host) | Usuário    | Senha      |
|-------------|------------------|--------------|------------|------------|
| MySQL 8.4   | `c-pm-mysql84`     | `33061`      | `root`     | `password` |
| MariaDB 11.4| `c-bd-mariadb114`  | `33062`      | `root`     | `password` |
| PostgreSQL  | `c-pe-postgres18`  | `54321`      | `postgres` | `password` |