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

## 3. Pré-requisitos

O `cphp` exige que o git esteja configurado globalmente na máquina antes de executar qualquer comando:

```bash
git config --global user.name "Seu Nome"
git config --global user.email "seu.email@example.com"
```

## 4. Configurar o PATH

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

O `cphp` **reescreve automaticamente o endereço de bind para `0.0.0.0`** e **mapeia a porta para o host** nos comandos de servidor abaixo, tornando o servidor acessível via `localhost` na máquina real.

| Servidor | Comando | Comportamento automático |
|---|---|---|
| PHP built-in | `cphp -S localhost:8080` | bind reescrito para `0.0.0.0:8080`, porta `8080` mapeada no host |
| Laravel Artisan | `cphp artisan serve` | injeta `--host=0.0.0.0`, porta `8000` mapeada no host |
| Symfony server | `cphp -s symfony server:start` | injeta `--allow-all-ip`, porta `8000` mapeada no host |

> Passar `--host=localhost` ou `--host=127.0.0.1` explicitamente também é reescrito para `0.0.0.0`. Qualquer outro valor de `--host` é preservado sem alteração.

### Acessando pelo navegador

A porta é mapeada automaticamente para o host. Basta acessar `http://127.0.0.1:<PORTA>` no navegador da máquina real.

```bash
# PHP built-in server — acesse http://127.0.0.1:8080
cphp -S localhost:8080

# Artisan serve — acesse http://127.0.0.1:8000
cphp artisan serve
# porta customizada — acesse http://127.0.0.1:9000
cphp artisan serve --port=9000

# Symfony server — acesse http://127.0.0.1:8000
cphp -s symfony server:start
# porta customizada — acesse http://127.0.0.1:9000
cphp -s symfony server:start --port=9000
```

O endereço de acesso é exibido no terminal antes do servidor subir. Pressione `Ctrl+C` para encerrar.

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