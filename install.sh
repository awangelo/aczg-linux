#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${HOME}/.local/bin/aczg"
LOG_DIR="${HOME}/.local/log/aczg"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASHRC="${HOME}/.bashrc"
SOURCE_LINE="source ${INSTALL_DIR}/aliases.sh"

print_info() {
    echo -e "[INFO] $1"
}

print_warn() {
    echo -e "[WARN] $1"
}

print_error() {
    echo -e "[ERRO] $1"
}

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif [[ -f /etc/gentoo-release ]]; then
        echo "gentoo"
    else
        echo "unknown"
    fi
}

// Funciona para apt, dnf, pacman, emerge
install_package() {
    local package="$1"
    local distro
    distro=$(detect_distro)
    
    print_info "Instalando ${package}..."
    
    case "$distro" in
        ubuntu|debian|linuxmint|pop)
            sudo apt update && sudo apt install -y "$package"
            ;;
        fedora)
            sudo dnf install -y "$package"
            ;;
        arch|manjaro|endeavouros)
            sudo pacman -S --noconfirm "$package"
            ;;
        gentoo)
            sudo emerge --ask=n "$package"
            ;;
        *)
            print_error "Distro não suportada: ${distro}"
            print_warn "Instale manualmente: ${package}"
            return 1
            ;;
    esac
}

get_package_name() {
    local generic_name="$1"
    local distro
    distro=$(detect_distro)
    
    case "$generic_name" in
        crontab)
            case "$distro" in
                ubuntu|debian|linuxmint|pop)
                    echo "cron"
                    ;;
                fedora)
                    echo "cronie"
                    ;;
                arch|manjaro|endeavouros)
                    echo "cronie"
                    ;;
                gentoo)
                    echo "sys-process/cronie"
                    ;;
                *)
                    echo "cron"
                    ;;
            esac
            ;;
        *)
            echo "$generic_name"
            ;;
    esac
}

check_and_install_dependencies() {
    print_info "Verificando dependências..."
    
    local deps=("git" "crontab")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        print_info "Todas as dependências estão instaladas."
        return 0
    fi
    
    print_warn "Dependências faltando: ${missing[*]}"
    
    for dep in "${missing[@]}"; do
        local package
        package=$(get_package_name "$dep")
        install_package "$package" || print_warn "Não foi possível instalar ${dep}"
    done
    
    # Habilita e inicia o serviço cron se necessário
    if [[ " ${missing[*]} " =~ " crontab " ]]; then
        local distro
        distro=$(detect_distro)
        case "$distro" in
            arch|manjaro|endeavouros|fedora)
                print_info "Habilitando serviço cronie..."
                sudo systemctl enable --now cronie 2>/dev/null || true
                ;;
        esac
    fi
}

create_directories() {
    print_info "Criando diretórios..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$LOG_DIR"
    
    print_info "  ${INSTALL_DIR}"
    print_info "  ${LOG_DIR}"
}

copy_scripts() {
    print_info "Copiando scripts..."
    
    cp "${SCRIPT_DIR}/scripts/"*.sh "$INSTALL_DIR/"
    
    cp "${SCRIPT_DIR}/config/aliases.sh" "$INSTALL_DIR/"
    
    chmod +x "${INSTALL_DIR}/"*.sh
    
    print_info "Scripts instalados em ${INSTALL_DIR}"
}

setup_bashrc() {
    print_info "Configurando ~/.bashrc..."
    
    # Cria .bashrc se não existir
    if [[ ! -f "$BASHRC" ]]; then
        print_warn "~/.bashrc não existe, criando..."
        touch "$BASHRC"
    fi
    
    echo "" >> "$BASHRC"
    echo "$SOURCE_LINE" >> "$BASHRC"
    print_info "Linha adicionada ao ~/.bashrc"
}

show_success_message() {
    echo ""
    echo "Comandos disponíveis:"
    echo "  aczgnew      - Criar novo projeto ACZG"
    echo "  aczginit     - Criar branch de feature"
    echo "  aczgfinish   - Finalizar branch de feature"
    echo "  aczglog      - Ver logs do CI"
    echo ""
}

check_and_install_dependencies
create_directories
copy_scripts
setup_bashrc
show_success_message

exec bash
