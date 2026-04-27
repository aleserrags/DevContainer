SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VALID_VERSIONS=("8.2" "8.3" "8.5")
DEFAULT_VERSION="8.5"
VERSION="$DEFAULT_VERSION"
SERVICE="php"
XDEBUG_ENABLED=false

# Parsing das flags -p (versão PHP), -s (serviço) e --xdebug
# Para imediatamente em qualquer flag/argumento desconhecido
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p)
            shift
            VERSION="$1"
            shift
            ;;
        -s)
            shift
            SERVICE="$1"
            shift
            ;;
        --xdebug)
            XDEBUG_ENABLED=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Valida a versão
VALID=false
for V in "${VALID_VERSIONS[@]}"; do
    if [[ "$V" == "$VERSION" ]]; then
        VALID=true
        break
    fi
done

if [[ "$VALID" == false ]]; then
    echo "Versão PHP '$VERSION' não disponível. Versões válidas: ${VALID_VERSIONS[*]}" >&2
    exit 1
fi

# Copia os argumentos restantes para um array mutável.
# Isso permite que as funções de detecção de servidor abaixo
# modifiquem os argumentos antes de passá-los ao docker run,
# sem afetar nenhum outro comando.
CMD_ARGS=("$@")

# Permite --xdebug em qualquer posição sem repassar a flag ao comando final.
# Exemplo: cphp artisan serve --xdebug
if [[ ${#CMD_ARGS[@]} -gt 0 ]]; then
    FILTERED_ARGS=()
    for arg in "${CMD_ARGS[@]}"; do
        if [[ "$arg" == "--xdebug" ]]; then
            XDEBUG_ENABLED=true
            continue
        fi
        FILTERED_ARGS+=("$arg")
    done
    CMD_ARGS=("${FILTERED_ARGS[@]}")
fi

# Porta do servidor detectado. Vazia = nenhum servidor identificado.
# Quando definida, run_in_container adiciona -p PORT:PORT ao docker run
# (mapeando a porta para o host) e exibe o endereço de acesso.
SERVER_PORT=""

# ─────────────────────────────────────────────────────────────
# Detecção e reescrita de argumentos de servidores de desenvolvimento
#
# Servidores PHP embutem por padrão no loopback (127.0.0.1),
# ficando inacessíveis de fora do container. As funções abaixo
# reescrevem automaticamente o endereço de bind para 0.0.0.0
# (todas as interfaces), permitindo acesso via IP do container.
# ─────────────────────────────────────────────────────────────

# Retorna 0 se o valor passado é um endereço loopback
# (localhost ou 127.0.0.1), que precisa ser reescrito.
_is_loopback() {
    [[ "$1" == "localhost" || "$1" == "127.0.0.1" ]]
}

# Percorre CMD_ARGS a partir de start_idx procurando --port=VALOR ou --port VALOR.
# Se encontrar, define SERVER_PORT com o valor da porta.
_extract_port_flag() {
    local start_idx="$1" i
    for (( i=start_idx; i<${#CMD_ARGS[@]}; i++ )); do
        if [[ "${CMD_ARGS[$i]}" == --port=* ]]; then
            SERVER_PORT="${CMD_ARGS[$i]#--port=}"
            return
        elif [[ "${CMD_ARGS[$i]}" == "--port" && -n "${CMD_ARGS[$((i+1))]}" ]]; then
            SERVER_PORT="${CMD_ARGS[$((i+1))]}"
            return
        fi
    done
}

# Trata: php -S <host:port>
# O built-in server do PHP aceita apenas o formato host:port.
# Sempre reescreve o host para 0.0.0.0, preservando a porta original.
# Define SERVER_PORT para que run_in_container mapeie a porta no host.
_rewrite_php_builtin_server() {
    local i
    for (( i=0; i<${#CMD_ARGS[@]}; i++ )); do
        if [[ "${CMD_ARGS[$i]}" == "-S" ]]; then
            local addr="${CMD_ARGS[$((i+1))]}"
            local port="${addr##*:}"  # tudo depois do ":"

            CMD_ARGS[$((i+1))]="0.0.0.0:${port}"
            SERVER_PORT="$port"
            break
        fi
    done
}

# Trata: artisan serve [--host=<valor>] [--port=<valor>]
# Se --host não foi passado, injeta --host=0.0.0.0 logo após "serve".
# Se --host=localhost ou --host=127.0.0.1 foi passado, reescreve para 0.0.0.0.
# Qualquer outro valor de --host é preservado conforme especificado.
# Define SERVER_PORT (padrão 8000, sobrescrito por --port se presente).
_rewrite_artisan_serve() {
    local i found_artisan=false serve_idx=-1

    # Localiza "artisan" seguido de "serve"
    for (( i=0; i<${#CMD_ARGS[@]}; i++ )); do
        if [[ "${CMD_ARGS[$i]}" == "artisan" ]]; then
            found_artisan=true
        fi
        if [[ "$found_artisan" == true && "${CMD_ARGS[$i]}" == "serve" ]]; then
            serve_idx=$i
            break
        fi
    done

    [[ $serve_idx -eq -1 ]] && return  # não é artisan serve, nada a fazer

    # Porta padrão do artisan serve; sobrescrita por --port se presente
    SERVER_PORT="8000"
    _extract_port_flag $((serve_idx + 1))

    # Verifica se --host já foi especificado
    local host_idx=-1 host_val=""
    for (( i=serve_idx+1; i<${#CMD_ARGS[@]}; i++ )); do
        if [[ "${CMD_ARGS[$i]}" == --host=* ]]; then
            host_idx=$i
            host_val="${CMD_ARGS[$i]#--host=}"  # extrai o valor após "="
            break
        fi
    done

    if [[ $host_idx -eq -1 ]]; then
        # --host não foi passado: injeta logo após "serve"
        CMD_ARGS=("${CMD_ARGS[@]:0:$((serve_idx+1))}" "--host=0.0.0.0" "${CMD_ARGS[@]:$((serve_idx+1))}")
    elif _is_loopback "$host_val"; then
        # --host=localhost ou --host=127.0.0.1: reescreve para 0.0.0.0
        CMD_ARGS[$host_idx]="--host=0.0.0.0"
    fi
    # Qualquer outro valor de --host é mantido intacto
}

# Trata: symfony server:start [--port=<valor>]
# Injeta --allow-all-ip se ainda não estiver presente.
# Esse flag é o equivalente do Symfony para bind em 0.0.0.0.
# Define SERVER_PORT (padrão 8000, sobrescrito por --port se presente).
_rewrite_symfony_server_start() {
    local i found_server_start=false has_allow_all_ip=false start_idx=-1

    for (( i=0; i<${#CMD_ARGS[@]}; i++ )); do
        if [[ "${CMD_ARGS[$i]}" == "server:start" ]]; then
            found_server_start=true
            start_idx=$i
        fi
        [[ "${CMD_ARGS[$i]}" == "--allow-all-ip" ]] && has_allow_all_ip=true
    done

    [[ "$found_server_start" == false ]] && return  # não é server:start, nada a fazer

    # Porta padrão do symfony server; sobrescrita por --port se presente
    SERVER_PORT="8000"
    _extract_port_flag $((start_idx + 1))

    # Injeta --allow-all-ip se ainda não estiver presente
    [[ "$has_allow_all_ip" == false ]] && CMD_ARGS+=("--allow-all-ip")
}

# Executa as três detecções em sequência.
# Apenas o comando correspondente ao serviço atual será afetado;
# todos os outros passam sem qualquer modificação.
_rewrite_php_builtin_server
_rewrite_artisan_serve
_rewrite_symfony_server_start

# Função principal que executa o serviço no container
run_in_container() {
    local git_name git_email composer_cache
    
    # Lê configurações do git — obrigatório que estejam definidas
    git_name=$(git config --global user.name 2>/dev/null)
    git_email=$(git config --global user.email 2>/dev/null)
    
    # Valida se ambas as configurações estão presentes
    if [[ -z "$git_name" ]]; then
        echo "Erro: git user.name não configurado globalmente." >&2
        echo "Execute: git config --global user.name 'Seu Nome'" >&2
        exit 1
    fi
    
    if [[ -z "$git_email" ]]; then
        echo "Erro: git user.email não configurado globalmente." >&2
        echo "Execute: git config --global user.email 'seu.email@example.com'" >&2
        exit 1
    fi
    
    composer_cache="${XDG_CACHE_HOME:-$HOME/.cache}/composer"
    mkdir -p "$composer_cache"

    # Argumentos base do docker run, comuns a todos os modos
    local docker_args=(
        -v "$(pwd)":/app
        -v "$SCRIPT_DIR/../php/$VERSION/php.ini:/usr/local/etc/php/conf.d/custom.ini"
        -v "$composer_cache":/tmp/composer
        -w /app
        --network dev-net
        --user "$(id -u):$(id -g)"
        -e HOME=/tmp
        -e COMPOSER_HOME=/tmp/composer
        -e GIT_AUTHOR_NAME="$git_name"
        -e GIT_AUTHOR_EMAIL="$git_email"
        -e GIT_COMMITTER_NAME="$git_name"
        -e GIT_COMMITTER_EMAIL="$git_email"
    )

    if [[ "$XDEBUG_ENABLED" == true ]]; then
        docker_args+=(
            --add-host=host.docker.internal:host-gateway
            -e XDEBUG_MODE=debug,develop
            -e XDEBUG_TRIGGER=1
            -e XDEBUG_CONFIG=client_host=host.docker.internal\ client_port=9003\ idekey=VSCODE
        )
        echo -e "\033[0;36m  Xdebug ativo:\033[0m escutando no host.docker.internal:9003 (idekey=VSCODE)" >&2
    fi

    if [[ -n "$SERVER_PORT" ]]; then
        # Modo servidor: mapeia a porta para o host (-p PORT:PORT) para que
        # localhost:PORT na máquina real seja encaminhado ao container.
        # Exibe o endereço de acesso antes de subir o servidor.
        docker_args+=(-p "$SERVER_PORT:$SERVER_PORT")
        echo -e "\033[0;32m  Servidor disponível em:\033[0m http://127.0.0.1:$SERVER_PORT  \033[0;90m(Ctrl+C para parar)\033[0m" >&2
        echo "" >&2
    fi

    docker run --rm -it \
        "${docker_args[@]}" \
        "php:$VERSION-dev" "$SERVICE" "${CMD_ARGS[@]}"
}
