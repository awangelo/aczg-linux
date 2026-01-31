#!/usr/bin/env bash

set -euo pipefail

show_usage() {
    echo "Uso: aczgnew <nome-projeto> [caminho]"
    echo ""
    echo "Argumentos:"
    echo "  nome-projeto  Nome do projeto [obrigatório, sem espaços]"
    echo "  caminho       Diretório onde criar o projeto [opcional, default: atual]"
    echo ""
    echo "Exemplo:"
    echo "  aczgnew meu-projeto ~/projetos"
    exit 1
}

validate_name() {
    local name="$1"
    
    # Nome não foi fornecido
    if [[ -z "$name" ]]; then
        echo -e "Erro: Nome do projeto não pode ser vazio.\n"
        show_usage
        exit 1
    fi
    
    # Verifica se contém espaços ou caracteres especiais
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "Erro: Nome do projeto deve conter apenas letras, números, hífen e underscore.\n"
        show_usage
        exit 1
    fi
}

create_project() {
    local project_name="$1"
    local base_path="$2"
    local full_path="${base_path}/${project_name}"
    
    if [[ -d "$full_path" ]]; then
        echo "Erro: '$full_path' já existe."
        exit 1
    fi
    
    echo "Criando $full_path..."
    mkdir -p "$full_path"
    
    echo "Criando README.md..."
    echo "projeto ${project_name} inicializado...." > "${full_path}/README.md"
    
    echo "Inicializando repositório Git..."
    cd "$full_path"
    git init
    git branch -M main
    git add README.md
    git commit -m "first commit - repositório configurado"
    
    echo ""
    echo "Projeto '${project_name}' criado com sucesso em: ${full_path}"
    echo "Para acessar: cd ${full_path}"
}

# Verifica se foi passado o nome do projeto
if [[ $# -lt 1 ]]; then
    show_usage
fi

PROJECT_NAME="$1"
BASE_PATH="${2:-.}"

# Converte caminho relativo para absoluto
BASE_PATH="$(cd "$BASE_PATH" 2>/dev/null && pwd)" || {
    echo "Erro: Caminho '$2' não existe."
    exit 1
}

validate_name "$PROJECT_NAME"
create_project "$PROJECT_NAME" "$BASE_PATH"
