#!/bin/sh
# Dotty bootstrap — curl-pipeable entry point
# Usage: sh -c "$(curl -fsSL https://raw.github.com/gplancke/dotty/main/bootstrap.sh)"
set -eu

DOTTY_DIR="${HOME}/.local/share/dotty"
DOTTY_REPO="https://github.com/gplancke/dotty.git"

###############################################
# Detect OS
###############################################
detect_os() {
  case "$(uname -s)" in
    Darwin)
      DISTRO="darwin"
      ;;
    Linux)
      if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
          fedora|rhel|centos|rocky|almalinux) DISTRO="fedora" ;;
          arch|manjaro|endeavouros|garuda|cachyos) DISTRO="arch" ;;
          ubuntu|debian|pop|elementary|linuxmint) DISTRO="debian" ;;
          alpine) DISTRO="alpine" ;;
          *) DISTRO="unknown" ;;
        esac
      else
        DISTRO="unknown"
      fi
      ;;
    *)
      DISTRO="unknown"
      ;;
  esac
}

###############################################
# Install python3 + pip (Linux only)
###############################################
install_python() {
  python3 -m pip --version >/dev/null 2>&1 && return 0

  printf '[DOTTY] Installing python3...\n'
  case "$DISTRO" in
    debian)
      sudo apt-get update -qq
      sudo apt-get install -qq -y python3 python3-pip python3-venv >/dev/null
      ;;
    fedora)
      sudo dnf install -q -y python3 python3-pip >/dev/null
      ;;
    arch)
      sudo pacman -Syu --noconfirm -q >/dev/null 2>&1
      sudo pacman -S --noconfirm -q python python-pip >/dev/null 2>&1
      ;;
    alpine)
      sudo apk update -q
      sudo apk add -q python3 py3-pip
      ;;
  esac
}

###############################################
# Install Ansible via pip
###############################################
install_ansible() {
  command -v ansible-playbook >/dev/null 2>&1 && return 0

  printf '[DOTTY] Installing Ansible...\n'

  case "$DISTRO" in
    darwin)
      # Ensure Xcode CLI tools
      if ! xcode-select -p >/dev/null 2>&1; then
        printf '[DOTTY] Installing Xcode Command Line Tools...\n'
        xcode-select --install 2>/dev/null || true
        printf '[DOTTY] Please complete the Xcode CLI tools install, then re-run this script.\n'
        exit 1
      fi
      python3 -m pip install --user --break-system-packages -q ansible 2>/dev/null || \
        python3 -m pip install --user -q ansible
      ;;
    *)
      install_python
      python3 -m pip install --user --break-system-packages -q ansible 2>/dev/null || \
        python3 -m pip install --user -q ansible
      ;;
  esac

  # Ensure pip user bin is on PATH
  PYTHON_USER_BIN="$(python3 -c 'import sysconfig; print(sysconfig.get_path("scripts", "posix_user"))')"
  export PATH="${PYTHON_USER_BIN}:${HOME}/.local/bin:${PATH}"
}

###############################################
# Clone or update repo
###############################################
clone_repo() {
  if [ -d "${DOTTY_DIR}/.git" ]; then
    printf '[DOTTY] Updating dotty repo...\n'
    git -C "${DOTTY_DIR}" pull --ff-only
  else
    printf '[DOTTY] Cloning dotty repo...\n'
    git clone "${DOTTY_REPO}" "${DOTTY_DIR}"
  fi
}

###############################################
# Install galaxy requirements
###############################################
install_galaxy() {
  if [ -f "${DOTTY_DIR}/requirements.yml" ]; then
    printf '[DOTTY] Installing Ansible Galaxy requirements...\n'
    ansible-galaxy collection install -r "${DOTTY_DIR}/requirements.yml" >/dev/null
  fi
}

###############################################
# Prompt for install mode
###############################################
prompt_mode() {
  printf '\nSelect install mode:\n'
  printf '  1) dev        (default)\n'
  printf '  2) full\n'
  printf '  3) container\n'
  printf 'Choice [1]: '
  read CHOICE < /dev/tty || CHOICE="1"
  case "$CHOICE" in
    2) INSTALL_MODE="full" ;;
    3) INSTALL_MODE="container" ;;
    *) INSTALL_MODE="dev" ;;
  esac
}

###############################################
# Prompt for GUI apps
###############################################
prompt_gui() {
  printf '\nInstall GUI apps? [y/N]:'
  read GUI_CHOICE < /dev/tty || GUI_CHOICE="n"
  case "$GUI_CHOICE" in
    [yY]) INSTALL_GUI="true" ;;
    *) INSTALL_GUI="false" ;;
  esac
}

###############################################
# Prompt for vault password
###############################################
prompt_vault() {
  VAULT_PASS_FILE="$(mktemp)"
  printf 'Vault password: '
  stty -echo < /dev/tty 2>/dev/null || true
  read VAULT_PASS < /dev/tty
  stty echo < /dev/tty 2>/dev/null || true
  printf '\n'
  printf '%s' "${VAULT_PASS}" > "${VAULT_PASS_FILE}"
  chmod 600 "${VAULT_PASS_FILE}"
}

###############################################
# Run playbook
###############################################
run_playbook() {
  cd "${DOTTY_DIR}"

  BECOME_FLAG="--ask-become-pass"
  if [ "$(id -u)" = "0" ]; then
    BECOME_FLAG=""
  fi

  # shellcheck disable=SC2086
  ansible-playbook site.yml \
    --vault-password-file "${VAULT_PASS_FILE}" \
    ${BECOME_FLAG} \
    -e "install_mode=${INSTALL_MODE}" \
    -e "install_gui=${INSTALL_GUI}"
}

###############################################
# Cleanup
###############################################
cleanup() {
  if [ -n "${VAULT_PASS_FILE:-}" ] && [ -f "${VAULT_PASS_FILE}" ]; then
    rm -f "${VAULT_PASS_FILE}"
  fi
}

###############################################
# Main
###############################################
main() {
  trap cleanup EXIT

  detect_os
  if [ "$DISTRO" = "unknown" ]; then
    printf '[DOTTY] Error: unsupported OS\n'
    exit 1
  fi

  install_ansible
  clone_repo
  install_galaxy
  prompt_mode
  prompt_gui
  prompt_vault
  run_playbook

  printf '\n[DOTTY] Provisioning complete!\n'
}

main "$@"
