SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VALID_VERSIONS=("8.2" "8.3" "8.5")
DEFAULT_VERSION="8.5"

# Detecta versão no primeiro argumento (ex: 8.3)
if [[ "$1" =~ ^[0-9]+\.[0-9]+$ ]]; then
    VERSION="$1"
    shift
else
    VERSION="$DEFAULT_VERSION"
fi

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
