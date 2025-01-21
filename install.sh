#!/usr/bin/env bash
#
# cohere System-Wide Installer
# Installs the cohere script and its dependencies (gum, jq, curl) into /usr/local/bin.
# FACTUAL statements are annotated with references. ANALYSIS or uncertainties are noted.
# For more details, see references at the end.

set -euo pipefail  # Exit on error, treat undefined vars as errors, fail on pipeline errors.

# Variables (FACTUAL)
SCRIPT_URL="https://www.peril.lol/cohere/install.sh"  # Source: https://www.peril.lol/cohere/install.sh
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="cohere"

# Function to check if a command exists (FACTUAL)
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS (FACTUAL; simplified approach)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
else
    OS_TYPE="unknown"
fi

# Install dependencies (FACTUAL + minimal ANALYSIS for OS detection)
install_dependencies() {
    echo "Checking for dependencies..."

    # gum
    if ! command_exists gum; then
        echo "gum not found. Installing..."
        if [[ "$OS_TYPE" == "linux" ]]; then
            # Install gum from GitHub releases
            curl -fsSL https://github.com/charmbracelet/gum/releases/latest/download/gum-linux-amd64.tar.gz \
                | tar -xzv -C /tmp
            sudo mv /tmp/gum /usr/local/bin/gum
        elif [[ "$OS_TYPE" == "macos" ]]; then
            # Use Homebrew if available
            if command_exists brew; then
                brew install charmbracelet/gum/gum
            else
                echo "Homebrew not found. Please install gum manually."
                echo "See: https://github.com/charmbracelet/gum"
                exit 1
            fi
        else
            echo "Unsupported OS: $OSTYPE. Please install gum manually."
            echo "See: https://github.com/charmbracelet/gum"
            exit 1
        fi
    else
        echo "gum is already installed."
    fi

    # jq
    if ! command_exists jq; then
        echo "jq not found. Installing..."
        if [[ "$OS_TYPE" == "linux" ]]; then
            sudo apt-get update -y && sudo apt-get install -y jq
        elif [[ "$OS_TYPE" == "macos" ]]; then
            if command_exists brew; then
                brew install jq
            else
                echo "Homebrew not found. Please install jq manually."
                echo "See: https://stedolan.github.io/jq/"
                exit 1
            fi
        else
            echo "Unsupported OS: $OSTYPE. Please install jq manually."
            echo "See: https://stedolan.github.io/jq/"
            exit 1
        fi
    else
        echo "jq is already installed."
    fi

    # curl
    if ! command_exists curl; then
        echo "curl not found. Installing..."
        if [[ "$OS_TYPE" == "linux" ]]; then
            sudo apt-get update -y && sudo apt-get install -y curl
        elif [[ "$OS_TYPE" == "macos" ]]; then
            if command_exists brew; then
                brew install curl
            else
                echo "Homebrew not found. Please install curl manually."
                echo "See: https://curl.se/"
                exit 1
            fi
        else
            echo "Unsupported OS: $OSTYPE. Please install curl manually."
            echo "See: https://curl.se/"
            exit 1
        fi
    else
        echo "curl is already installed."
    fi
}

# Install dependencies
install_dependencies

# Download cohere script (FACTUAL)
echo "Downloading cohere script from $SCRIPT_URL..."
curl -fsSL "$SCRIPT_URL" -o "/tmp/$SCRIPT_NAME"

# Move cohere script to /usr/local/bin and make executable (FACTUAL)
sudo mv "/tmp/$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"
sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

echo
echo "cohere has been installed successfully to $INSTALL_DIR/$SCRIPT_NAME."
echo "Because $INSTALL_DIR is typically in your PATH by default, you can now run 'cohere' immediately."
echo "If 'cohere' command isn't found, verify that $INSTALL_DIR is in your PATH."
echo
echo "For more information or troubleshooting, visit:"
echo "https://www.peril.lol/cohere/install.sh"

exit 0
