#!/usr/bin/env bash
set -euo pipefail

show_usage() {
    echo "Uso: aczginit <nome-entrega>"
    echo ""
    echo "Argumentos:"
    echo "  nome-entrega  Nome da feature/entrega [obrigatório, sem espaços]"
    echo ""
    echo "Exemplo:"
    echo "  aczginit login-sistema"
    echo "    Criará a branch: feat-login-sistema"
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
        exit 1
    fi
}

init_feature_branch() {
    local feature_name="$1"
    local branch_name="feat-${feature_name}"
    
    # Verifica se a branch já existe localmente
    if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
        echo "Erro: Branch '${branch_name}' já existe."
        exit 1
    fi
    
    git status
    echo ""
    
    # Cria e faz checkout na nova branch
    echo "Criando branch '${branch_name}'..."
    git checkout -b "$branch_name"
    echo ""
    
    git branch -a
    echo ""
    
    echo "Branch '${branch_name}' criada com sucesso!"
}

# Verifica se foi passado o nome da entrega
if [[ $# -lt 1 ]]; then
    show_usage
fi

FEATURE_NAME="$1"

check_git_repo
validate_name "$FEATURE_NAME"
init_feature_branch "$FEATURE_NAME"
