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
        "php:$VERSION-dev" "$SERVICE" "$@"
}
