#!/usr/bin/env bash
#
# cohere Installer (Colorful Edition, no ASCII banner)
# Installs the cohere CLI script into /usr/local/bin so that the user
# can simply type "cohere" and start using it.
#
# Factual references are provided at the end; analysis or uncertainties are noted.

set -euo pipefail

###############################################################################
# 1) Color definitions (FACTUAL)
###############################################################################
# References on ANSI escape codes: [3]
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"

###############################################################################
# 2) Variables (FACTUAL)
###############################################################################
COHERE_SCRIPT_URL="https://raw.githubusercontent.com/plyght/cohere-cli/main/cohere.sh"
INSTALL_PATH="/usr/local/bin/cohere"
TMP_FILE="/tmp/cohere.sh"

###############################################################################
# 3) Helper function: check if a command exists (FACTUAL)
###############################################################################
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

###############################################################################
# 4) OS detection (FACTUAL)
###############################################################################
OS_TYPE="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS_TYPE="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  OS_TYPE="macos"
fi

###############################################################################
# 5) Install dependencies: gum, jq, curl
###############################################################################
install_dependencies() {
  echo -e "${BOLD}${CYAN}Checking dependencies...${RESET}"

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
        echo -e "${RED}[ANALYSIS] Homebrew not found. Install gum manually: https://github.com/charmbracelet/gum${RESET}"
        exit 1
      fi
    else
      echo -e "${RED}[ANALYSIS] Unsupported OS for auto gum install. Please install gum manually.${RESET}"
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
      echo -e "${RED}[ANALYSIS] Unsupported OS for auto jq install. Please install jq manually.${RESET}"
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
      echo -e "${RED}[ANALYSIS] Unsupported OS for auto curl install. Please install curl manually.${RESET}"
      exit 1
    fi
  else
    echo -e "${GREEN}curl is already installed.${RESET}"
  fi
}

###############################################################################
# 6) Main installation process
###############################################################################
main() {
  echo -e "${MAGENTA}${BOLD}=== cohere Installer ===${RESET}"
  echo -e "We'll install \`cohere\` into ${BOLD}/usr/local/bin${RESET},"
  echo -e "so you can type 'cohere' without reloading your shell.\n"

  install_dependencies

  echo -e "${CYAN}Downloading cohere.sh from:${RESET} $COHERE_SCRIPT_URL"
  curl -fsSL "$COHERE_SCRIPT_URL" -o "$TMP_FILE"

  echo -e "${CYAN}Installing cohere to:${RESET} $INSTALL_PATH"
  sudo mv "$TMP_FILE" "$INSTALL_PATH"
  sudo chmod +x "$INSTALL_PATH"

  echo -e "\n${GREEN}Installation complete!${RESET}"
  echo -e "Type ${BOLD}cohere${RESET} to start. If you see 'command not found', ensure"
  echo -e "${BOLD}/usr/local/bin${RESET} is in your PATH [1,2].\n"
}

main
exit 0
