#!/usr/bin/env bash
set -euo pipefail

DEFAULT_HOUR="23"
DEFAULT_MINUTE="00"
LOG_DIR="${HOME}/.local/log/aczg"
LOG_FILE="${LOG_DIR}/ci.log"
CRON_TAG="ACZG-AUTOCOMMIT"

show_usage() {
    echo "Uso: aczg-autocommit --setup <caminho-repositorio> [hora]"
    echo "     aczg-autocommit --run <caminho-repositorio>"
    echo ""
    echo "Modos:"
    echo "  --setup  Configura a cron job para commits diários"
    echo "  --run    Executa o commit"
    echo ""
    echo "Argumentos:"
    echo "  caminho-repositorio  Caminho absoluto do repositório Git"
    echo "  hora                 Hora do commit diário [0-23, default: ${DEFAULT_HOUR}]"
    echo ""
    echo "Exemplos:"
    echo "  aczg-autocommit --setup /home/user/meu-projeto"
    echo "  aczg-autocommit --setup /home/user/meu-projeto 18"
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

validate_repo() {
    local repo_path="$1"
    
    if [[ ! -d "$repo_path" ]]; then
        echo "Erro: Diretório não existe: ${repo_path}"
        exit 1
    fi
    
    if ! git -C "$repo_path" rev-parse --is-inside-work-tree &>/dev/null; then
        echo "Erro: Não é um repositório Git: ${repo_path}"
        exit 1
    fi
}

setup_cron() {
    local repo_path="$1"
    local hour="${2:-$DEFAULT_HOUR}"
    local script_path
    script_path=$(realpath "$0")
    
    validate_repo "$repo_path"
    
    # Valida a hora
    if [[ ! "$hour" =~ ^[0-9]+$ ]] || [[ "$hour" -lt 0 ]] || [[ "$hour" -gt 23 ]]; then
        echo "Erro: Hora inválida '${hour}'. Use um valor entre 0 e 23."
        exit 1
    fi
    
    # Converte para caminho absoluto
    repo_path=$(realpath "$repo_path")
    
    # Expressão cron: minuto hora * * * (diário)
    local cron_expression="${DEFAULT_MINUTE} ${hour} * * *"
    
    # Remove entrada antiga (se existir)
    local temp_cron
    temp_cron=$(mktemp)
    crontab -l 2>/dev/null | grep -v "# ${CRON_TAG}:${repo_path}$" > "$temp_cron" || true
    
    # Adiciona nova entrada
    echo "${cron_expression} ${script_path} --run ${repo_path} # ${CRON_TAG}:${repo_path}" >> "$temp_cron"
    
    # Instala o novo crontab
    crontab "$temp_cron"
    rm "$temp_cron"
    
    echo "Cron job de autocommit configurado com sucesso!"
    echo "  Repositório: ${repo_path}"
    echo "  Horário: ${hour}:${DEFAULT_MINUTE} (diariamente)"
    echo "  Log: ${LOG_FILE}"
    echo ""
    echo "Para verificar: crontab -l"
}

run_commit() {
    local repo_path="$1"
    local project_name
    project_name=$(basename "$repo_path")
    
    # Valida o repositório
    validate_repo "$repo_path"
    
    cd "$repo_path"
    
    # Verifica se há mudanças
    if git diff --quiet && git diff --cached --quiet; then
        # Verifica também arquivos não rastreados
        if [[ -z $(git ls-files --others --exclude-standard) ]]; then
            log_message "AUTOCOMMIT" "$project_name" "Nada a commitar"
            echo "Nada a commitar"
            exit 0
        fi
    fi
    
    local commit_date
    commit_date=$(date '+%Y-%m-%d %H:%M')
    local commit_message="auto-commit ${commit_date}"
    
    git add .
    git commit -m "$commit_message"
    
    log_message "AUTOCOMMIT" "$project_name" "Commit realizado: ${commit_message}"
    send_notification "ACZG Autocommit" "Projeto ${project_name}: commit realizado"
    
    echo "Commit realizado: ${commit_message}"
}

if [[ $# -lt 2 ]]; then
    show_usage
fi

MODE="$1"
REPO_PATH="$2"
HOUR="${3:-}"

case "$MODE" in
    --setup)
        setup_cron "$REPO_PATH" "$HOUR"
        ;;
    --run)
        run_commit "$REPO_PATH"
        ;;
    *)
        echo "Erro: Modo inválido '${MODE}'"
        show_usage
        ;;
esac
