.DEFAULT_GOAL := help
.ONESHELL:

help:
	@grep '^[a-zA-Z0-9\._-]\+:\s.*#\s\+.*$$' $(lastword $(MAKEFILE_LIST)) \
		| sort \
		| awk 'BEGIN {FS = ":.*?#"}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: git
git: # Install git
	@if ! command -v $@ >/dev/null; then
		sudo add-apt-repository -y -P ppa:git-core/ppa
		sudo apt update
		sudo apt install -y $@
	fi
	if [ "$(filter $@,$(MAKECMDGOALS))" ]; then
		$@ --version
	fi

.PHONY: asdf
asdf: git # Install asdf
	@dest=$(HOME)/.asdf
	if [ ! -d $$dest ]; then
		git clone https://github.com/asdf-vm/asdf.git $$dest --branch v0.14.0
		. "$$dest/asdf.sh"
		. "$$dest/completions/asdf.bash"
	fi
	if [ "$(filter $@,$(MAKECMDGOALS))" ]; then
		echo $$dest
		$@ --version
	fi

.PHONY: fzf
fzf: git # Install fzf
	@dest=$(HOME)/.fzf
	if [ ! -d $$dest ]; then
		git clone --depth 1 https://github.com/junegunn/fzf.git $$dest
		$$dest/fzf/install
		source $$dest/.bashrc
	fi
	echo $$dest
	$@ --version

.PHONY: docker
docker:
	@if ! command -v $@ >/dev/null; then
		# Add Docker's official GPG key:
		sudo apt-get update
		sudo apt-get install ca-certificates curl
		sudo install -m 0755 -d /etc/apt/keyrings
		sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
		sudo chmod a+r /etc/apt/keyrings/docker.asc
		# Add the repository to Apt sources:
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$$VERSION_CODENAME") stable" \
			| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
		sudo apt update
		sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	fi
	if [ "$(filter $@,$(MAKECMDGOALS))" ]; then
		$@ --version
	fi

.PHONY: gh
gh: # Install gh
	@if ! command -v $@ >/dev/null; then
		sudo mkdir -p -m 755 /etc/apt/keyrings
		wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
			| sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
		sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
			| sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
		sudo apt update
		sudo apt install -y $@
	fi
	$@ --version

rust: asdf # Install rust
	@name=rust
	version=1.79.0
	asdf plugin-add rust
	asdf install $$name $$version
	asdf global $$name $$version
	if [ "$(filter $@,$(MAKECMDGOALS))" ]; then
		$@ --version
	fi

.PHONY: zellij
zellij: rust # Install zellij a Terminal Multiplexers
	cargo install --locked zellij
	$@ --version

.PHONY: python
python: asdf # Install python
	@name=python
	version=3.12.0
	asdf plugin-add $$name
	asdf install $$name $$version
	asdf global $$name $$version
	pip install --upgrade pip
	if [ "$(filter $@,$(MAKECMDGOALS))" ]; then
		$@ --version
	fi

.PHONY: pgcli
pgcli: python # Install pgcli
	pip install pgcli
	$@ --version

.PHONY: vim
vim: # Install vim
	@echo "vim"
	$@ --version

.PHONY: link
link: # Link dotfiles
	@files=$$(find ./src -type f | sort)
	echo "The following dotfiles will be linked:"
	for f in $$files; do
		target=$$(readlink -f $$f)
		link_name="$(HOME)/$$(realpath --relative-base=src $$f)"
		echo "\e[36m$$link_name\e[m -> $$target"
	done
	@read -p "Do you want to proceed with linking these files? (y/n)" yn
	if [ "$$yn" != "y" ]; then
		echo "Operation aborted."
		exit
	fi
	for f in $$files; do
			target=$$(readlink -f $$f)
			link_name="$(HOME)/$$(realpath --relative-base=src $$f)"
			link_dir=$$(dirname $$link_name)
			# if [ -f $$link_name ] && [ "$$(readlink $$link_name)" != "$$target" ]; then
			# TODO backup
			# fi
			if [ ! -d "$$link_dir" ]; then
					mkdir -p "$$link_dir"
			fi
			ln -sfv $$target $$link_name
	done

.PHONY: test
test: docker # Test this Makefile on a docekr container
	@docker compose -f ./compose-ubuntu.yaml up -d --build
	for t in git; do
		docker compose exec -it app sh -c "cd /dots; make $$t"
	done
	docker compose -f ./compose-ubuntu.yaml down
