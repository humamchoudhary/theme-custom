#!/bin/bash

# Linux Development Environment Setup Script
# Compatible with Ubuntu, Arch, Fedora, and other major distributions
# Usage: ./setup.sh [package1] [package2] ... or ./setup.sh --interactive

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Logging function
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    elif [[ -f /etc/arch-release ]]; then
        DISTRO="arch"
    elif [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
    else
        error "Unsupported distribution"
        exit 1
    fi
    
    log "Detected distribution: $DISTRO"
}

# Package manager commands
get_package_manager() {
    case $DISTRO in
        ubuntu|debian|pop|linuxmint)
            PKG_MANAGER="apt"
            UPDATE_CMD="sudo apt update"
            INSTALL_CMD="sudo apt install -y"
            ;;
        arch|manjaro|endeavouros)
            PKG_MANAGER="pacman"
            UPDATE_CMD="sudo pacman -Sy"
            INSTALL_CMD="sudo pacman -S --noconfirm"
            AUR_HELPER="yay"
            ;;
        fedora|rhel|centos)
            PKG_MANAGER="dnf"
            UPDATE_CMD="sudo dnf update -y"
            INSTALL_CMD="sudo dnf install -y"
            ;;
        opensuse*)
            PKG_MANAGER="zypper"
            UPDATE_CMD="sudo zypper refresh"
            INSTALL_CMD="sudo zypper install -y"
            ;;
        *)
            error "Unsupported package manager for $DISTRO"
            exit 1
            ;;
    esac
}

# Update system
update_system() {
    log "Updating system packages..."
    $UPDATE_CMD
}

# Install AUR helper for Arch-based systems
install_aur_helper() {
    if [[ $DISTRO == "arch" ]] && ! command -v yay &> /dev/null; then
        log "Installing yay AUR helper..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd - > /dev/null
        rm -rf /tmp/yay
    fi
}

# Install Python latest
install_python() {
    log "Installing Python..."
    case $DISTRO in
        ubuntu|debian|pop|linuxmint)
            $INSTALL_CMD python3 python3-pip python3-venv python-is-python3
            ;;
        arch|manjaro|endeavouros)
            $INSTALL_CMD python python-pip
            ;;
        fedora|rhel|centos)
            $INSTALL_CMD python3 python3-pip python3-venv
            sudo alternatives --install /usr/bin/python python /usr/bin/python3 1
            ;;
        opensuse*)
            $INSTALL_CMD python3 python3-pip
            sudo ln -sf /usr/bin/python3 /usr/bin/python
            ;;
    esac
    
    # Install common Python packages
    pip install --user --upgrade pip setuptools wheel
}

# Install Node.js latest
install_node() {
    log "Installing Node.js..."
    
    # Install Node Version Manager (nvm)
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    
    # Source nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install latest LTS Node.js
    nvm install --lts
    nvm use --lts
    nvm alias default node
    
    # Install global packages
    npm install -g npm@latest yarn pnpm
}

# Install Go latest
install_golang() {
    log "Installing Go..."
    
    # Get latest Go version
    GO_VERSION=$(curl -s https://golang.org/VERSION?m=text)
    
    # Download and install
    wget -O /tmp/go.tar.gz "https://golang.org/dl/${GO_VERSION}.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
    
    # Add to PATH if not already there
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    fi
    if [[ -f ~/.zshrc ]] && ! grep -q "/usr/local/go/bin" ~/.zshrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
    fi
}

# Install Neovim
install_neovim() {
    log "Installing Neovim..."
    case $DISTRO in
        ubuntu|debian|pop|linuxmint)
            # Install from official PPA for latest version
            sudo add-apt-repository ppa:neovim-ppa/unstable -y
            sudo apt update
            $INSTALL_CMD neovim
            ;;
        arch|manjaro|endeavouros)
            $INSTALL_CMD neovim
            ;;
        fedora|rhel|centos)
            $INSTALL_CMD neovim
            ;;
        opensuse*)
            $INSTALL_CMD neovim
            ;;
    esac
    
    # Create alias for vim
    if ! grep -q "alias vim=nvim" ~/.bashrc; then
        echo "alias vim=nvim" >> ~/.bashrc
    fi
    if [[ -f ~/.zshrc ]] && ! grep -q "alias vim=nvim" ~/.zshrc; then
        echo "alias vim=nvim" >> ~/.zshrc
    fi
}

# Install Zsh
install_zsh() {
    log "Installing Zsh..."
    case $DISTRO in
        ubuntu|debian|pop|linuxmint)
            $INSTALL_CMD zsh
            ;;
        arch|manjaro|endeavouros)
            $INSTALL_CMD zsh
            ;;
        fedora|rhel|centos)
            $INSTALL_CMD zsh
            ;;
        opensuse*)
            $INSTALL_CMD zsh
            ;;
    esac
    
    # Change default shell to zsh
    if [[ $SHELL != */zsh ]]; then
        log "Changing default shell to zsh..."
        chsh -s $(which zsh)
    fi
}

# Install Oh My Zsh
install_ohmyzsh() {
    log "Installing Oh My Zsh..."
    if [[ ! -d ~/.oh-my-zsh ]]; then
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        log "Oh My Zsh already installed"
    fi
    
    # Install popular plugins
    ZSH_CUSTOM="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"
    
    # zsh-autosuggestions
    if [[ ! -d $ZSH_CUSTOM/plugins/zsh-autosuggestions ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
    fi
    
    # zsh-syntax-highlighting
    if [[ ! -d $ZSH_CUSTOM/plugins/zsh-syntax-highlighting ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
    fi
    
    # powerlevel10k theme
    if [[ ! -d $ZSH_CUSTOM/themes/powerlevel10k ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
    fi
}

# Install Kitty terminal
install_kitty() {
    log "Installing Kitty terminal..."
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    
    # Create desktop entry
    mkdir -p ~/.local/share/applications
    cat > ~/.local/share/applications/kitty.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=kitty
GenericName=Terminal emulator
Comment=Fast, feature-rich, cross-platform, GPU-based terminal
TryExec=kitty
Exec=kitty
Icon=kitty
Categories=System;TerminalEmulator;
EOF
    
    # Add to PATH
    if ! grep -q "~/.local/kitty.app/bin" ~/.bashrc; then
        echo 'export PATH="$HOME/.local/kitty.app/bin:$PATH"' >> ~/.bashrc
    fi
    if [[ -f ~/.zshrc ]] && ! grep -q "~/.local/kitty.app/bin" ~/.zshrc; then
        echo 'export PATH="$HOME/.local/kitty.app/bin:$PATH"' >> ~/.zshrc
    fi
}

# Install Hyprland
install_hyprland() {
    log "Installing Hyprland..."
    case $DISTRO in
        ubuntu|debian|pop|linuxmint)
            warn "Hyprland installation on Ubuntu/Debian requires manual compilation"
            log "Installing dependencies..."
            $INSTALL_CMD meson wget build-essential ninja-build cmake-extras cmake gettext gettext-base fontconfig libfontconfig-dev libffi-dev libxml2-dev libdrm-dev libxkbcommon-x11-dev libxkbregistry-dev libxkbcommon-dev libpixman-1-dev libudev-dev libseat-dev seatd libxcb-dri3-dev libvulkan-dev libvulkan-volk-dev vulkan-validationlayers-dev libvkfft-dev libgulkan-dev libegl-dev libgles2 libegl1-mesa-dev glslang-tools libinput-bin libinput-dev libxcb-composite0-dev libavutil-dev libavcodec-dev libavformat-dev libxkbcommon-x11-dev libpango1.0-dev libcairo-dev libcairo-gobject2 libcairo-gobject-dev libgtk-3-dev libgdk-pixbuf2.0-dev
            warn "Please compile Hyprland manually or use a different distribution"
            ;;
        arch|manjaro|endeavouros)
            $INSTALL_CMD hyprland
            ;;
        fedora)
            sudo dnf copr enable solopasha/hyprland -y
            $INSTALL_CMD hyprland
            ;;
        *)
            warn "Hyprland installation not supported for $DISTRO"
            ;;
    esac
}

# Install Waybar
install_waybar() {
    log "Installing Waybar..."
    case $DISTRO in
        ubuntu|debian|pop|linuxmint)
            $INSTALL_CMD waybar
            ;;
        arch|manjaro|endeavouros)
            $INSTALL_CMD waybar
            ;;
        fedora|rhel|centos)
            $INSTALL_CMD waybar
            ;;
        opensuse*)
            $INSTALL_CMD waybar
            ;;
    esac
}

# Install MongoDB
install_mongodb() {
    log "Installing MongoDB..."
    case $DISTRO in
        ubuntu|debian|pop|linuxmint)
            # Import MongoDB GPG key
            curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
            
            # Add MongoDB repository
            echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
            
            sudo apt update
            $INSTALL_CMD mongodb-org
            
            # Start and enable MongoDB
            sudo systemctl start mongod
            sudo systemctl enable mongod
            ;;
        arch|manjaro|endeavouros)
            $INSTALL_CMD mongodb-bin
            sudo systemctl start mongodb
            sudo systemctl enable mongodb
            ;;
        fedora|rhel|centos)
            # Add MongoDB repository
            cat > /tmp/mongodb-org-7.0.repo << EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
            sudo mv /tmp/mongodb-org-7.0.repo /etc/yum.repos.d/
            $INSTALL_CMD mongodb-org
            sudo systemctl start mongod
            sudo systemctl enable mongod
            ;;
        *)
            warn "MongoDB installation not supported for $DISTRO"
            ;;
    esac
}

# Install additional useful software
install_additional() {
    log "Installing additional useful software..."
    
    # Common development tools
    case $DISTRO in
        ubuntu|debian|pop|linuxmint)
            $INSTALL_CMD git curl wget vim tree htop neofetch bat exa fd-find ripgrep fzf tmux docker.io docker-compose
            ;;
        arch|manjaro|endeavouros)
            $INSTALL_CMD git curl wget vim tree htop neofetch bat exa fd ripgrep fzf tmux docker docker-compose
            ;;
        fedora|rhel|centos)
            $INSTALL_CMD git curl wget vim tree htop neofetch bat exa fd-find ripgrep fzf tmux docker docker-compose
            ;;
        opensuse*)
            $INSTALL_CMD git curl wget vim tree htop neofetch bat exa fd ripgrep fzf tmux docker docker-compose
            ;;
    esac
    
    # Enable and start Docker
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
    
    # Install Rust and Cargo
    if ! command -v rustc &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source ~/.cargo/env
    fi
    
    # Install common Rust tools
    cargo install starship zoxide
}

# Copy configuration files
copy_configs() {
    log "Copying configuration files..."
    
    # Check if configs directory exists
    if [[ -d "$SCRIPT_DIR/configs" ]]; then
        # Copy .zshrc if exists
        if [[ -f "$SCRIPT_DIR/configs/.zshrc" ]]; then
            cp "$SCRIPT_DIR/configs/.zshrc" ~/.zshrc
            log "Copied .zshrc"
        fi
        
        # Copy .config directory if exists
        if [[ -d "$SCRIPT_DIR/configs/.config" ]]; then
            mkdir -p ~/.config
            cp -r "$SCRIPT_DIR/configs/.config/"* ~/.config/
            log "Copied .config files"
        fi
        
        # Copy other dotfiles
        for file in "$SCRIPT_DIR/configs/."*; do
            if [[ -f "$file" ]] && [[ "$(basename "$file")" != ".zshrc" ]]; then
                cp "$file" ~/
                log "Copied $(basename "$file")"
            fi
        done
    else
        warn "No configs directory found at $SCRIPT_DIR/configs"
    fi
}

# Available packages
declare -A PACKAGES=(
    ["python"]="install_python"
    ["node"]="install_node"
    ["golang"]="install_golang"
    ["neovim"]="install_neovim"
    ["zsh"]="install_zsh"
    ["ohmyzsh"]="install_ohmyzsh"
    ["kitty"]="install_kitty"
    ["hyprland"]="install_hyprland"
    ["waybar"]="install_waybar"
    ["mongodb"]="install_mongodb"
    ["additional"]="install_additional"
)

# Interactive mode
interactive_mode() {
    echo -e "${BLUE}Available packages:${NC}"
    local i=1
    local package_list=()
    
    for package in "${!PACKAGES[@]}"; do
        echo "$i) $package"
        package_list+=("$package")
        ((i++))
    done
    
    echo -e "\n${YELLOW}Enter package numbers separated by spaces (e.g., 1 3 5) or 'all' for everything:${NC}"
    read -r selection
    
    if [[ "$selection" == "all" ]]; then
        SELECTED_PACKAGES=("${!PACKAGES[@]}")
    else
        SELECTED_PACKAGES=()
        for num in $selection; do
            if [[ $num -ge 1 && $num -le ${#package_list[@]} ]]; then
                SELECTED_PACKAGES+=("${package_list[$((num-1))]}")
            fi
        done
    fi
}

# Main installation function
install_packages() {
    for package in "${SELECTED_PACKAGES[@]}"; do
        if [[ -n "${PACKAGES[$package]}" ]]; then
            log "Installing $package..."
            ${PACKAGES[$package]}
        else
            warn "Unknown package: $package"
        fi
    done
}

# Help function
show_help() {
    cat << EOF
Linux Development Environment Setup Script

Usage: $0 [OPTIONS] [PACKAGES...]

OPTIONS:
    -h, --help          Show this help message
    -i, --interactive   Run in interactive mode
    -a, --all          Install all packages
    --no-update        Skip system update
    --no-configs       Skip copying configuration files

PACKAGES:
    python      Install latest Python with pip
    node        Install latest Node.js with npm/yarn
    golang      Install latest Go
    neovim      Install Neovim
    zsh         Install Zsh
    ohmyzsh     Install Oh My Zsh with plugins
    kitty       Install Kitty terminal
    hyprland    Install Hyprland window manager
    waybar      Install Waybar
    mongodb     Install MongoDB
    additional  Install additional development tools

Examples:
    $0 --interactive
    $0 python node golang neovim
    $0 --all
    $0 zsh ohmyzsh kitty --no-update

Configuration files should be placed in a 'configs' directory next to this script.
EOF
}

# Parse command line arguments
INTERACTIVE=false
INSTALL_ALL=false
SKIP_UPDATE=false
SKIP_CONFIGS=false
SELECTED_PACKAGES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        -a|--all)
            INSTALL_ALL=true
            shift
            ;;
        --no-update)
            SKIP_UPDATE=true
            shift
            ;;
        --no-configs)
            SKIP_CONFIGS=true
            shift
            ;;
        *)
            if [[ -n "${PACKAGES[$1]}" ]]; then
                SELECTED_PACKAGES+=("$1")
            else
                warn "Unknown package: $1"
            fi
            shift
            ;;
    esac
done

# Main execution
main() {
    log "Starting Linux Development Environment Setup"
    
    # Detect distribution and set package manager
    detect_distro
    get_package_manager
    
    # Update system unless skipped
    if [[ "$SKIP_UPDATE" != true ]]; then
        update_system
    fi
    
    # Install AUR helper for Arch
    if [[ $DISTRO == "arch" ]]; then
        install_aur_helper
    fi
    
    # Determine packages to install
    if [[ "$INSTALL_ALL" == true ]]; then
        SELECTED_PACKAGES=("${!PACKAGES[@]}")
    elif [[ "$INTERACTIVE" == true ]]; then
        interactive_mode
    elif [[ ${#SELECTED_PACKAGES[@]} -eq 0 ]]; then
        warn "No packages specified. Use --interactive, --all, or specify package names."
        show_help
        exit 1
    fi
    
    # Install selected packages
    install_packages
    
    # Copy configuration files unless skipped
    if [[ "$SKIP_CONFIGS" != true ]]; then
        copy_configs
    fi
    
    log "Setup completed successfully!"
    log "Please restart your terminal or run 'source ~/.bashrc' and 'source ~/.zshrc' to apply changes."
    
    if [[ "$SHELL" != */zsh ]] && [[ " ${SELECTED_PACKAGES[*]} " =~ " zsh " ]]; then
        log "Note: Default shell has been changed to zsh. Please log out and log back in for the change to take effect."
    fi
}

# Run main function
main "$@"
