VAULT_FILE ?= $(HOME)/.dotty-vault-pass
MODE ?= server

.PHONY: apply apply-container remote vault-edit galaxy

apply:
	ansible-playbook site.yml --vault-password-file $(VAULT_FILE) --ask-become-pass -e install_mode=$(MODE)

apply-container:
	ansible-playbook site.yml --vault-password-file $(VAULT_FILE) -e install_mode=container

remote:
	ansible-playbook site.yml -i inventory/hosts.yml -l $(HOST) --vault-password-file $(VAULT_FILE) --ask-become-pass -e install_mode=$(MODE)

vault-edit:
	ansible-vault edit group_vars/all/vault.yml --vault-password-file $(VAULT_FILE)

galaxy:
	ansible-galaxy collection install -r requirements.yml
