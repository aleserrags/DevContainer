SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VALID_VERSIONS=("8.2" "8.3" "8.5")
DEFAULT_VERSION="8.5"
VERSION="$DEFAULT_VERSION"
SERVICE="php"

# Parsing das flags -p (versão PHP) e -s (serviço)
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

# Trata: php -S <host:port>
# O built-in server do PHP aceita apenas o formato host:port.
# Qualquer host loopback (ou ausência de especificação do host,
# que também resulta em bind local) é reescrito para 0.0.0.0,
# preservando a porta original.
_rewrite_php_builtin_server() {
    local i
    for (( i=0; i<${#CMD_ARGS[@]}; i++ )); do
        if [[ "${CMD_ARGS[$i]}" == "-S" ]]; then
            local addr="${CMD_ARGS[$((i+1))]}"
            local host="${addr%%:*}"  # tudo antes do ":"
            local port="${addr##*:}"  # tudo depois do ":"

            # Sempre reescreve o host para 0.0.0.0,
            # independente do que o usuário passou.
            CMD_ARGS[$((i+1))]="0.0.0.0:${port}"
            break
        fi
    done
}

# Trata: artisan serve [--host=<valor>]
# Se --host não foi passado, injeta --host=0.0.0.0 logo após "serve".
# Se --host=localhost ou --host=127.0.0.1 foi passado, reescreve para 0.0.0.0.
# Qualquer outro valor de --host é preservado conforme especificado.
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

# Trata: symfony server:start
# Injeta --allow-all-ip se ainda não estiver presente.
# Esse flag é o equivalente do Symfony para bind em 0.0.0.0.
_rewrite_symfony_server_start() {
    local i found_server_start=false

    for (( i=0; i<${#CMD_ARGS[@]}; i++ )); do
        if [[ "${CMD_ARGS[$i]}" == "server:start" ]]; then
            found_server_start=true
        fi
        # Se --allow-all-ip já está presente, nada a fazer
        if [[ "${CMD_ARGS[$i]}" == "--allow-all-ip" ]]; then
            return
        fi
    done

    if [[ "$found_server_start" == true ]]; then
        # Injeta --allow-all-ip ao final dos argumentos
        CMD_ARGS+=("--allow-all-ip")
    fi
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
    git_name=$(git config --global user.name 2>/dev/null || echo "Developer")
    git_email=$(git config --global user.email 2>/dev/null || echo "dev@localhost")
    composer_cache="${XDG_CACHE_HOME:-$HOME/.cache}/composer"
    mkdir -p "$composer_cache"

    docker run --rm -it \
        -v "$(pwd)":/app \
        -v "$SCRIPT_DIR/../php/$VERSION/php.ini:/usr/local/etc/php/conf.d/custom.ini" \
        -v "$composer_cache":/tmp/composer \
        -w /app \
        --network dev-net \
        --user "$(id -u):$(id -g)" \
        -e HOME=/tmp \
        -e COMPOSER_HOME=/tmp/composer \
        -e GIT_AUTHOR_NAME="$git_name" \
        -e GIT_AUTHOR_EMAIL="$git_email" \
        -e GIT_COMMITTER_NAME="$git_name" \
        -e GIT_COMMITTER_EMAIL="$git_email" \
        "php:$VERSION-dev" "$SERVICE" "${CMD_ARGS[@]}"
}
