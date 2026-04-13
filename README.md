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

O script `cphp` é o único ponto de entrada. Use `-p` para a versão PHP (padrão: `8.5`) e `-s` para o serviço (padrão: `php`).

Execute dentro do diretório do projeto:

```bash
# PHP (padrão 8.5)
cphp script.php
cphp -r "echo PHP_VERSION;"
cphp -S localhost:8080

# PHP versão específica
cphp -p 8.3 script.php
cphp -p 8.2 -r "echo PHP_VERSION;"

# Composer
cphp -s composer install
cphp -p 8.3 -s composer install

# Symfony CLI
cphp -s symfony new meu-projeto --webapp
cphp -p 8.2 -s symfony new meu-projeto
```

Versões disponíveis: `8.2`, `8.3`, `8.5`

## Conexões

### De dentro de um container (aplicação rodando via `cphp`)

Use o nome do container como host e a **porta padrão** do banco:

| Banco        | HOST              | Porta  | Usuário    | Senha      |
|--------------|-------------------|--------|------------|------------|
| MySQL 8.4    | `c-pm-mysql84`    | `3306` | `root`     | `password` |
| MariaDB 11.4 | `c-bd-mariadb114` | `3306` | `root`     | `password` |
| PostgreSQL   | `c-pe-postgres18` | `5432` | `postgres` | `password` |

### Do host (máquina local, ferramentas como DBeaver, Datagrip etc.)

Use `localhost` como host e as **portas mapeadas**:

| Banco        | HOST        | Porta   | Usuário    | Senha      |
|--------------|-------------|---------|------------|------------|
| MySQL 8.4    | `localhost` | `33061` | `root`     | `password` |
| MariaDB 11.4 | `localhost` | `33062` | `root`     | `password` |
| PostgreSQL   | `localhost` | `54321` | `postgres` | `password` |