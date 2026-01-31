#!/usr/bin/env bash
set -euo pipefail

DEFAULT_CRON="0 */6 * * *"
LOG_DIR="${HOME}/.local/log/aczg"
LOG_FILE="${LOG_DIR}/ci.log"
CRON_TAG="ACZG-CI-BUILD"

show_usage() {
    echo "Uso: aczg-ci --setup <caminho-projeto> [cron-expression]"
    echo "     aczg-ci --run <caminho-projeto>"
    echo ""
    echo "Modos:"
    echo "  --setup  Configura a cron job para o projeto"
    echo "  --run    Executa o build/testes"
    echo ""
    echo "Argumentos:"
    echo "  caminho-projeto  Caminho absoluto do projeto Gradle"
    echo "  cron-expression  Expressão cron [opcional, default: '${DEFAULT_CRON}']"
    echo ""
    echo "Exemplos:"
    echo "  aczg-ci --setup /home/user/meu-projeto"
    echo "  aczg-ci --setup /home/user/meu-projeto '0 */2 * * *'"
    exit 1
}

log_message() {
    local level="$1"
    local project="$2"
    local message="$3"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    mkdir -p "$LOG_DIR"
    echo "[ACZG-CI] ${timestamp} - ${level} - ${project} - ${message}" >> "$LOG_FILE"
}

send_notification() {
    local title="$1"
    local message="$2"
    
    # Tenta usar o display padrão
    local display="${DISPLAY:-:0}"
    
    DISPLAY="$display" notify-send "$title" "$message" 2>/dev/null || true
}

validate_project() {
    local project_path="$1"
    
    if [[ ! -d "$project_path" ]]; then
        echo "Erro: Diretório do projeto não existe: ${project_path}"
        exit 1
    fi
    
    if [[ ! -f "${project_path}/build.gradle" ]]; then
        echo "Erro: build.gradle não encontrado"
        exit 1
    fi
    
    if [[ ! -f "${project_path}/gradlew" ]]; then
        echo "Erro: gradlew não encontrado no projeto"
        exit 1
    fi
}

setup_cron() {
    local project_path="$1"
    local cron_expression="${2:-$DEFAULT_CRON}"
    local script_path
    script_path=$(realpath "$0")
    
    validate_project "$project_path"
    
    # Converte para caminho absoluto
    project_path=$(realpath "$project_path")
    
    # Remove entrada antiga (se existir)
    local temp_cron
    temp_cron=$(mktemp)
    crontab -l 2>/dev/null | grep -v "# ${CRON_TAG}:${project_path}$" > "$temp_cron" || true
    
    # Adiciona nova entrada
    echo "${cron_expression} ${script_path} --run ${project_path} # ${CRON_TAG}:${project_path}" >> "$temp_cron"
    
    # Instala o novo crontab
    crontab "$temp_cron"
    rm "$temp_cron"
    
    echo "Cron job configurado com sucesso!"
    echo "  Projeto: ${project_path}"
    echo "  Expressão: ${cron_expression}"
    echo "  Log: ${LOG_FILE}"
    echo ""
    echo "Para verificar: crontab -l"
}

run_build() {
    local project_path="$1"
    local project_name
    project_name=$(basename "$project_path")
    
    # Valida o projeto
    validate_project "$project_path"
    
    cd "$project_path"
    
    echo "Executando testes do projeto ${project_name}..."
    
    local output
    local exit_code=0
    
    output=$(./gradlew test 2>&1) || exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_message "BUILD SUCCESS" "$project_name" "Testes executados com sucesso"
        send_notification "ACZG CI - Sucesso" "Projeto ${project_name}: testes passaram"
        echo "BUILD SUCCESS"
    else
        log_message "BUILD FAILED" "$project_name" "Falha nos testes: ${output}"
        send_notification "ACZG CI - Falha" "Projeto ${project_name}: testes falharam"
        echo "BUILD FAILED"
        echo "$output"
        exit 1
    fi
}

if [[ $# -lt 2 ]]; then
    show_usage
fi

MODE="$1"
PROJECT_PATH="$2"
CRON_EXPR="${3:-}"

case "$MODE" in
    --setup)
        setup_cron "$PROJECT_PATH" "$CRON_EXPR"
        ;;
    --run)
        run_build "$PROJECT_PATH"
        ;;
    *)
        show_usage
        ;;
esac
