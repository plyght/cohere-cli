#!/usr/bin/env bash
#
# cohere Installer (Prettier Edition)
#
# Installs the cohere.sh script (from the given GitHub repo) into /usr/local/bin
# so you can run 'cohere' immediately *without* reloading your shell.
#
# If your system doesn't have /usr/local/bin in its PATH, see references [1,2].
#
# [ANALYSIS] The script requires sudo privileges for system-wide install. If you
# don't have sudo, place cohere in a user-specific directory (e.g., ~/.local/bin).

set -euo pipefail

###############################################################################
# 0) Color definitions & ASCII banner (FACTUAL)
###############################################################################
# For reference on ANSI escape codes, see [3].
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"

COHERE_ASCII="
${MAGENTA}   ____           _                    
  / ___|___ _ __ | |__   ___ _ __ ___  
 | |   / _ \\ '_ \\| '_ \\ / _ \\ '__/ _ \\ 
 | |__|  __/ |_) | | | |  __/ | |  __/ 
  \\____\\___| .__/|_| |_|\\___|_|  \\___| 
           |_|                        
${RESET}"

###############################################################################
# 1) Variables (FACTUAL)
###############################################################################
COHERE_SCRIPT_URL="https://raw.githubusercontent.com/plyght/cohere-cli/main/cohere.sh"
COHERE_INSTALL_PATH="/usr/local/bin/cohere"
TMP_FILE="/tmp/cohere.sh"

###############################################################################
# 2) Helper functions (FACTUAL)
###############################################################################
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

###############################################################################
# 3) OS detection (FACTUAL)
###############################################################################
OS_TYPE="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS_TYPE="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  OS_TYPE="macos"
fi

###############################################################################
# 4) Install dependencies (gum, jq, curl)
###############################################################################
install_dependencies() {
  echo -e "${CYAN}Checking dependencies...${RESET}"

  # gum
  if ! command_exists gum; then
    echo -e "${YELLOW}Installing gum...${RESET}"
    if [[ "$OS_TYPE" == "linux" ]]; then
      curl -fsSL https://github.com/charmbracelet/gum/releases/latest/download/gum-linux-amd64.tar.gz \
        | tar -xzv -C /tmp
      sudo mv /tmp/gum /usr/local/bin/gum
    elif [[ "$OS_TYPE" == "macos" ]]; then
      if command_exists brew; then
        brew install charmbracelet/gum/gum
      else
        echo -e "${RED}[ANALYSIS] Homebrew not found. Install gum manually from:${RESET} https://github.com/charmbracelet/gum"
        exit 1
      fi
    else
      echo -e "${RED}[ANALYSIS] Unsupported OS for automated gum install. Manual installation required.${RESET}"
      exit 1
    fi
  else
    echo -e "${GREEN}gum is already installed.${RESET}"
  fi

  # jq
  if ! command_exists jq; then
    echo -e "${YELLOW}Installing jq...${RESET}"
    if [[ "$OS_TYPE" == "linux" ]]; then
      sudo apt-get update -y && sudo apt-get install -y jq
    elif [[ "$OS_TYPE" == "macos" ]]; then
      if command_exists brew; then
        brew install jq
      else
        echo -e "${RED}[ANALYSIS] Homebrew not found. Install jq manually: https://stedolan.github.io/jq/${RESET}"
        exit 1
      fi
    else
      echo -e "${RED}[ANALYSIS] Unsupported OS for automated jq install. Manual installation required.${RESET}"
      exit 1
    fi
  else
    echo -e "${GREEN}jq is already installed.${RESET}"
  fi

  # curl
  if ! command_exists curl; then
    echo -e "${YELLOW}Installing curl...${RESET}"
    if [[ "$OS_TYPE" == "linux" ]]; then
      sudo apt-get update -y && sudo apt-get install -y curl
    elif [[ "$OS_TYPE" == "macos" ]]; then
      if command_exists brew; then
        brew install curl
      else
        echo -e "${RED}[ANALYSIS] Homebrew not found. Install curl manually: https://curl.se/${RESET}"
        exit 1
      fi
    else
      echo -e "${RED}[ANALYSIS] Unsupported OS for automated curl install. Manual installation required.${RESET}"
      exit 1
    fi
  else
    echo -e "${GREEN}curl is already installed.${RESET}"
  fi
}

###############################################################################
# 5) Main installation
###############################################################################
main() {
  # Show ASCII banner
  echo -e "$COHERE_ASCII\n"
  echo -e "${BOLD}Welcome to the cohere installer!${RESET}"
  echo -e "This will install \`cohere\` into ${BOLD}/usr/local/bin${RESET},"
  echo -e "so you can run ${BOLD}cohere${RESET} without reloading your shell.\n"

  install_dependencies

  echo -e "${CYAN}Downloading cohere.sh from:${RESET} $COHERE_SCRIPT_URL"
  curl -fsSL "$COHERE_SCRIPT_URL" -o "$TMP_FILE"

  echo -e "${CYAN}Installing cohere to:${RESET} $COHERE_INSTALL_PATH"
  sudo mv "$TMP_FILE" "$COHERE_INSTALL_PATH"
  sudo chmod +x "$COHERE_INSTALL_PATH"

  echo -e "\n${GREEN}cohere has been installed successfully!${RESET}"
  echo -e "Try running: ${BOLD}cohere${RESET}\n"
  echo -e "If you see 'command not found', confirm ${BOLD}/usr/local/bin${RESET} is in your PATH (see references [1,2]).\n"
}

main
exit 0
