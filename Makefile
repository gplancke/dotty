VAULT_FILE ?= $(HOME)/.dotty-vault-pass
MODE ?= dev
GUI ?= true

.PHONY: apply apply-container remote vault-edit galaxy

apply:
	ansible-playbook site.yml --vault-password-file $(VAULT_FILE) --ask-become-pass -e install_mode=$(MODE) -e install_gui=$(GUI)

apply-container:
	ansible-playbook site.yml --vault-password-file $(VAULT_FILE) -e install_mode=container -e install_gui=false

remote:
	ansible-playbook site.yml -i inventory/hosts.yml -l $(HOST) --vault-password-file $(VAULT_FILE) --ask-become-pass -e install_mode=$(MODE) -e install_gui=$(GUI)

vault-edit:
	ansible-vault edit group_vars/all/vault.yml --vault-password-file $(VAULT_FILE)

galaxy:
	ansible-galaxy collection install -r requirements.yml
