# Dotty

Ansible-first system provisioner for macOS and Linux.

## Quick Start

```sh
sh -c "$(curl -fsSL https://raw.github.com/gplancke/dotty/main/bootstrap.sh)"
```

The bootstrap script installs Python, pip, and Ansible, then clones this repo and runs the main playbook. You'll be prompted to choose an install mode and enter the vault password.

## What It Does

Dotty provisions a fresh machine in five phases:

1. **Essentials** — Core build tools and dependencies per distro
2. **Package managers** — Homebrew, Nix, Mise, Docker (based on feature flags)
3. **System packages** — Distro-specific packages, GUI casks on macOS, Flatpak on Linux
4. **Dotfiles** — Managed via [chezmoi](https://www.chezmoi.io/) with age encryption
5. **Shell** — Shell configuration and directory structure

## Install Modes

The bootstrap script prompts for one of three modes:

| Mode | Description |
|---|---|
| `server` (default) | Full provisioning without GUI apps |
| `desktop` | Everything in server + GUI casks / Flatpak |
| `container` | Minimal — no Homebrew, Mise, or Docker |

## Supported Platforms

- macOS (ARM64 + Intel)
- Debian / Ubuntu
- RedHat / Fedora
- Arch Linux
- Alpine Linux

## Minimum Requirements

- `curl` or `wget`
- `git`
- Internet access
- `sudo` access (non-root user)

## Re-running

You can safely re-run dotty at any time. Key behaviors:

- **Switching `install_mode`** — The chezmoi config is re-deployed every run, so dotfiles reflect the new mode immediately. `chezmoi update --force` re-applies all templates with the updated mode.
- **Package managers are install-only** — Homebrew, Mise, Docker, and Nix are installed but never removed. Switching to `container` mode skips those roles but does not uninstall previously-installed tools. To fully clean up, uninstall unwanted tools manually.
- **Idempotent** — Every role is safe to run repeatedly. Re-running on an already-provisioned machine is a no-op for components that are already present.

## Gotchas

- **macOS: Xcode CLT** — Must be installed before running bootstrap. The script will prompt but exits if missing.
- **macOS: Nix on Sequoia + FileVault** — The automated Nix installer fails. Install the `.pkg` manually from [nixos.org](https://nixos.org/download/).
- **macOS: No Docker Desktop** — Licensing concerns. Use [Colima](https://github.com/abiosoft/colima) or [OrbStack](https://orbstack.dev/) instead.
- **macOS: pip `--break-system-packages`** — Handled automatically by the bootstrap script.
- **All: Restart your shell** after provisioning for Mise / Nix to be available on `$PATH`.

## Configuration

Feature flags and variables live in `group_vars/all/main.yml`. Key toggles:

- `install_homebrew` — Enabled unless container mode
- `install_nix` — Disabled by default
- `install_mise` — Enabled unless container mode
- `install_docker` — Enabled for server/desktop

Secrets (chezmoi age key) are stored in `group_vars/all/vault.yml` (Ansible Vault encrypted).

## Project Structure

```
.
├── bootstrap.sh              # Curl-pipeable entry point
├── site.yml                  # Main playbook
├── ansible.cfg
├── requirements.yml          # Ansible Galaxy dependencies
├── Makefile
├── inventory/
│   └── hosts.yml
├── group_vars/
│   └── all/
│       ├── main.yml          # Feature flags and variables
│       └── vault.yml         # Encrypted secrets
└── roles/
    ├── essentials/           # Core build tools per distro
    ├── directories/          # User directory structure
    ├── shell/                # Shell configuration
    ├── homebrew/             # Homebrew install
    ├── nix/                  # Nix install
    ├── mise/                 # Mise runtime manager
    ├── docker/               # Docker per distro
    ├── system-packages/      # Distro packages, GUI casks, Flatpak
    ├── packages/             # User packages (brew, nix, mise)
    └── chezmoi/              # Dotfiles with age encryption
```
