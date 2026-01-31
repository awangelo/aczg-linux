#!/usr/bin/env bash
set -euo pipefail

MAIN_BRANCH="main"

show_usage() {
    echo "Uso: aczgfinish <nome-entrega>"
    echo ""
    echo "Argumentos:"
    echo "  nome-entrega  Nome da feature/entrega [obrigatório, sem espaços]"
    echo ""
    echo "Exemplo:"
    echo "  aczgfinish login-sistema"
    echo "    Fara merge da branch feat-login-sistema na ${MAIN_BRANCH} e a deletará."
    exit 1
}

check_git_repo() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "Erro: Não está dentro de um repositório Git."
        exit 1
    fi
}

validate_name() {
    local name="$1"
    
    # Verifica se está vazio
    if [[ -z "$name" ]]; then
        echo "Erro: Nome da entrega não pode ser vazio."
        exit 1
    fi
    
    # Verifica se contém espaços ou caracteres especiais
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Erro: Nome da entrega deve conter apenas letras, números, hífen e underscore."
        echo "Nome inválido: '$name'"
        exit 1
    fi
}

finish_feature_branch() {
    local feature_name="$1"
    local branch_name="feat-${feature_name}"
    
    # Verifica se a branch existe localmente
    if ! git show-ref --verify --quiet "refs/heads/${branch_name}"; then
        echo "Erro: Branch '${branch_name}' não existe."
        exit 1
    fi
    
    # Verifica se a branch main existe
    if ! git show-ref --verify --quiet "refs/heads/${MAIN_BRANCH}"; then
        echo "Erro: Branch '${MAIN_BRANCH}' não existe."
        exit 1
    fi
    
    # Faz checkout na main
    echo "Fazendo checkout na branch '${MAIN_BRANCH}'..."
    git checkout "$MAIN_BRANCH"
    echo ""
    
    # Realiza o merge da branch da feature
    echo "Fazendo merge da branch '${branch_name}'..."
    if ! git merge "$branch_name"; then
        echo ""
        echo "Erro: Conflitos detectados durante o merge."
        echo "Resolva os conflitos manualmente e depois delete a branch com:"
        echo "  git branch -d ${branch_name}"
        exit 1
    fi
    echo ""
    
    # Deleta a branch local
    echo "Deletando branch local '${branch_name}'..."
    git branch -d "$branch_name"
    echo ""
    
    # Tenta deletar a branch remota (ignora silenciosamente se não existir)
    if git show-ref --verify --quiet "refs/remotes/origin/${branch_name}"; then
        echo "Deletando branch remota '${branch_name}'..."
        git push origin --delete "$branch_name" 2>/dev/null || true
    fi
    
    echo "Feature '${feature_name}' finalizada com sucesso!"
}

# Verifica se foi passado o nome da entrega
if [[ $# -lt 1 ]]; then
    show_usage
fi

FEATURE_NAME="$1"

check_git_repo
validate_name "$FEATURE_NAME"
finish_feature_branch "$FEATURE_NAME"
