# DevContainer

## 1. Build das imagens PHP

```bash
docker build -t php:8.2-dev -f php/8.2/Dockerfile .
docker build -t php:8.3-dev -f php/8.3/Dockerfile .
docker build -t php:8.5-dev -f php/8.5/Dockerfile .
```

## 2. Certificados CA customizados (opcional)

Se o ambiente exigir um certificado CA privado (ex: proxy corporativo, serviços internos com SSL), coloque o arquivo `.crt` na pasta `certs/` antes de buildar as imagens:

```bash
cp /caminho/para/seu-certificado.crt certs/
```

O Dockerfile de cada versão verifica se o arquivo existe e o instala automaticamente como CA confiável no sistema operacional do container. Se a pasta `certs/` estiver vazia, o build continua normalmente sem erros.

> Apenas arquivos `.crt` no formato PEM são suportados pelo `update-ca-certificates`.

## 3. Subir os bancos

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

O script `cphp` é o único ponto de entrada. Use `-p` para a versão PHP (padrão: `8.5`), `-s` para o serviço (padrão: `php`) e `--xdebug` para ativar debug remoto sob demanda.

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

## 6. Debug com Xdebug + VS Code (DEVSENSE)

O Xdebug fica desligado por padrão e só é ativado quando você usa `--xdebug`.

### Executando com debug

```bash
# CLI
cphp --xdebug script.php
cphp --xdebug -r "echo 'debug';"

# PHP built-in server
cphp --xdebug -S localhost:8080

# Laravel Artisan
cphp --xdebug artisan serve
cphp --xdebug artisan serve --port=9000

# Symfony server
cphp --xdebug -s symfony server:start
cphp --xdebug -s symfony server:start --port=9001
```

Quando `--xdebug` está ativo, o `cphp` injeta automaticamente:

- `--add-host=host.docker.internal:host-gateway`
- `XDEBUG_MODE=debug,develop`
- `XDEBUG_TRIGGER=1`
- `XDEBUG_CONFIG=client_host=host.docker.internal client_port=9003 idekey=VSCODE`

### Exemplo de `launch.json` (DEVSENSE PHP)

Crie `.vscode/launch.json` no projeto PHP que você está depurando:

Configuração mínima que **não funciona sozinha** neste setup:

```json
{
  "name": "Listen for Xdebug",
  "type": "php",
  "request": "launch"
}
```

Use a configuração completa abaixo:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Listen for Xdebug (cphp)",
      "type": "php",
      "request": "launch",
      "port": 9003,
      "pathMappings": {
        "/app": "${workspaceFolder}"
      }
    }
  ]
}
```

`/app` é o caminho do código dentro do container (montado pelo `cphp`) e precisa mapear para `${workspaceFolder}` no VS Code. Sem `pathMappings`, o call stack pode aparecer, mas os breakpoints não param.

### Troubleshooting rápido

- A porta `9003` precisa estar livre no host.
- Inicie a configuração de debug no VS Code antes de executar o `cphp --xdebug ...`.
- Confirme o `pathMappings` com `"/app": "${workspaceFolder}"`.
- Verifique se a imagem da versão usada (`php:<versao>-dev`) foi rebuildada após mudanças no Dockerfile/extensões.

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
