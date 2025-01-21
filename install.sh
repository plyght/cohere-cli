#!/usr/bin/env bash

set -e

# Variables.
SCRIPT_URL="https://www.peril.lol/cohere/install.sh"  # Hosted install.sh in site repo
INSTALL_DIR="$HOME/bin"
SCRIPT_NAME="cohere"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install dependencies
install_dependencies() {
    echo "Checking for dependencies..."

    # Check for gum
    if ! command_exists gum; then
        echo "gum not found. Installing..."
        # Install gum (Linux example; adjust for macOS or other OS)
        curl -sSL https://github.com/charmbracelet/gum/releases/latest/download/gum-linux-amd64.tar.gz | tar -xzv -C /tmp
        sudo mv /tmp/gum /usr/local/bin/gum
    else
        echo "gum is already installed."
    fi

    # Check for jq
    if ! command_exists jq; then
        echo "jq not found. Installing..."
        # Install jq (Debian/Ubuntu example; adjust for other distros)
        sudo apt-get update && sudo apt-get install -y jq
    else
        echo "jq is already installed."
    fi

    # Check for curl
    if ! command_exists curl; then
        echo "curl not found. Installing..."
        sudo apt-get update && sudo apt-get install -y curl
    else
        echo "curl is already installed."
    fi
}

# Ensure ~/bin exists
mkdir -p "$INSTALL_DIR"

# Install dependencies
install_dependencies

# Download the script
echo "Downloading cohere.sh..."
curl -sL "$SCRIPT_URL" -o "$INSTALL_DIR/$SCRIPT_NAME"

# Make it executable
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# Add ~/bin to PATH if not already
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
    echo "Adding $INSTALL_DIR to PATH..."
    # Detect shell and update accordingly
    if [ -n "$BASH_VERSION" ]; then
        echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
        source ~/.bashrc
    elif [ -n "$ZSH_VERSION" ]; then
        echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
        source ~/.zshrc
    else
        echo "Please add $INSTALL_DIR to your PATH manually."
    fi
    echo "Please reload your terminal or run 'source ~/.bashrc' or 'source ~/.zshrc' to update your PATH."
else
    echo "$INSTALL_DIR is already in your PATH."
fi

echo "cohere.sh has been installed successfully! You can now run 'cohere' from your terminal."
