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

# PHP versão específica
cphp -p 8.3 script.php
cphp -p 8.2 -r "echo PHP_VERSION;"

# Composer
cphp -s composer install
cphp -p 8.3 -s composer install

# Symfony CLI
cphp -s symfony new meu-projeto --webapp
cphp -p 8.2 -s symfony new meu-projeto

# Artisan (Laravel/modules)
cphp artisan migrate
cphp artisan queue:work
cphp artisan tinker
```

Versões disponíveis: `8.2`, `8.3`, `8.5`

## 5. Servidores de desenvolvimento

O `cphp` **reescreve automaticamente o endereço de bind para `0.0.0.0`** nos comandos de servidor abaixo. Isso é necessário porque dentro de um container o loopback (`127.0.0.1`) é inacessível pelo navegador — apenas `0.0.0.0` (todas as interfaces) permite acesso externo via IP do container.

| Servidor | Comando | Comportamento automático |
|---|---|---|
| PHP built-in | `cphp -S localhost:8080` | bind reescrito para `0.0.0.0:8080` |
| Laravel Artisan | `cphp artisan serve` | injeta `--host=0.0.0.0` |
| Symfony server | `cphp -s symfony server:start` | injeta `--allow-all-ip` |

> Passar `--host=localhost` ou `--host=127.0.0.1` explicitamente também é reescrito para `0.0.0.0`. Qualquer outro valor de `--host` é preservado sem alteração.

### Acessando pelo navegador

Após subir o servidor, descubra o IP do container com:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -lq)
```

Em seguida acesse `http://<IP_DO_CONTAINER>:<PORTA>` no navegador.

**Exemplos:**

```bash
# PHP built-in server — acesse http://<IP>:8080
cphp -S localhost:8080

# Artisan serve — acesse http://<IP>:8000
cphp artisan serve
# porta customizada: acesse http://<IP>:9000
cphp artisan serve --port=9000

# Symfony server — acesse http://<IP>:8000
cphp -s symfony server:start
# ou com porta customizada: acesse http://<IP>:9000
cphp -s symfony server:start --port=9000
```

Todos os demais comandos (`php`, `composer`, `artisan`, `symfony console`, etc.) passam sem nenhuma modificação.

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