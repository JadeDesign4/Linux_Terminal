#!/bin/bash
set -e

echo "🚀 Initiating Complete Zsh Environment Setup..."

# 1. OS Detection and Complete Package Installation
if [ -f /etc/arch-release ]; then
    echo "📦 Arch Linux detected. Installing complete package list..."
    sudo pacman -Syu --needed zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search zsh-autocomplete zsh-lovers zshdb fzf --noconfirm

    # Arch Paths
    AUTO_SUGGEST="/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
    SYNTAX_HIGHLIGHT="/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    SUBSTRING_SEARCH="/usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh"
    AUTO_COMPLETE="/usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh"

elif [ -f /etc/debian_version ] || [ -f /etc/lsb-release ]; then
    echo "📦 Debian/Ubuntu detected. Installing equivalent packages..."
    sudo apt update
    sudo apt install -y zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search fzf
    
    # Note: zsh-autocomplete, zshdb, and zsh-lovers are often built from source or 
    # handled via git on Debian because they aren't always in primary apt stables.
    # We will clone zsh-autocomplete natively into a local folder for Debian users.
    AUTO_SUGGEST="/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    SYNTAX_HIGHLIGHT="/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    SUBSTRING_SEARCH="/usr/share/zsh-history-substring-search/zsh-history-substring-search.zsh"
    
    if [ ! -d "$HOME/.local/share/zsh-autocomplete" ]; then
        echo "📥 Downloading zsh-autocomplete for Debian..."
        git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git "$HOME/.local/share/zsh-autocomplete"
    fi
    AUTO_COMPLETE="$HOME/.local/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
else
    echo "❌ Unsupported OS."
    exit 1
fi

# 2. Change Default Shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "🔄 Switching default shell to Zsh..."
    chsh -s "$(which zsh)"
fi

# 3. Generating Config File
echo "📝 Compiling configuration into ~/.zshrc..."

cat << 'EOF' > ~/.zshrc
# -----------------------------------------------------
# COMPLETION & PATH SYSTEM
# -----------------------------------------------------
# Add system site-functions for zsh-completions package
fpath=(/usr/share/zsh/site-functions $fpath)

# Initialize completion engine
autoload -Uz compinit && compinit

# -----------------------------------------------------
# HISTORY CONFIGURATION
# -----------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt appendhistory
setopt sharehistory
setopt incappendhistory

# -----------------------------------------------------
# ADVANCED PLUGINS LOADING (Order is strictly critical)
# -----------------------------------------------------

# 1. Drop-down Menu Autocomplete (Must load early)
if [ -f "AUTO_COMPLETE_PLACEHOLDER" ]; then
    source "AUTO_COMPLETE_PLACEHOLDER"
fi

# 2. Syntax Highlighting (Must load before autosuggestions/substring)
if [ -f "SYNTAX_HIGHLIGHT_PLACEHOLDER" ]; then
    source "SYNTAX_HIGHLIGHT_PLACEHOLDER"
fi

# 3. Fish-like Autosuggestions
if [ -f "AUTO_SUGGEST_PLACEHOLDER" ]; then
    source "AUTO_SUGGEST_PLACEHOLDER"
fi

# 4. History Substring Search 
if [ -f "SUBSTRING_SEARCH_PLACEHOLDER" ]; then
    source "SUBSTRING_SEARCH_PLACEHOLDER"
    
    # Bind UP and DOWN arrow keys to search history for matching text matching your cursor position
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    
    # Vi-mode or Kitty specific alternative arrow-key mappings
    bindkey -M vicmd 'k' history-substring-search-up
    bindkey -M vicmd 'j' history-substring-search-down
fi

# -----------------------------------------------------
# ALIASES & EXPORTS
# -----------------------------------------------------
alias ls='ls --color=auto'
alias ll='ls -la'
alias grep='grep --color=auto'

EOF

# Replace placeholders inside the generated script file with actual system variables
sed -i "s|AUTO_COMPLETE_PLACEHOLDER|$AUTO_COMPLETE|g" ~/.zshrc
sed -i "s|SYNTAX_HIGHLIGHT_PLACEHOLDER|$SYNTAX_HIGHLIGHT|g" ~/.zshrc
sed -i "s|AUTO_SUGGEST_PLACEHOLDER|$AUTO_SUGGEST|g" ~/.zshrc
sed -i "s|SUBSTRING_SEARCH_PLACEHOLDER|$SUBSTRING_SEARCH|g" ~/.zshrc

echo "✅ Setup successfully completed! Relaunch Kitty terminal to enjoy your pristine manual configuration."
