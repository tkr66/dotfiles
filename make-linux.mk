.DEFAULT_GOAL := help
.ONESHELL:

help:
	@grep '^[a-zA-Z0-9\._-]\+:\s.*#\s\+.*$$' $(lastword $(MAKEFILE_LIST)) \
		| sort \
		| awk 'BEGIN {FS = ":.*?#"}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: base
base: # Install base packages
	sudo apt update && apt install -y \
		libxt-dev \
		libtool-bin \
		software-properties-common \
		clang

.PHONY: util
util: # Install utilities
	sudo apt update && apt install -y \
		wl-clipboard \
		gimp

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

.PHONY: mise
mise: # Install mise
	@if ! command -v $@ >/dev/null; then
		curl https://mise.run | sh
		~/.local/bin/mise --version
	fi
	if [ "$(filter $@,$(MAKECMDGOALS))" ]; then
		$@ --version
	fi

.PHONY: docker
docker: # Install docker
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

.PHONY: rust
rust: mise # Install rust
	@name=rust
	version=1.79.0
	mise use -g $$name@latest
	if [ "$(filter $@,$(MAKECMDGOALS))" ]; then
		if command -v rust-analyzer >/dev/null; then
			rustup component add rust-analyzer
		fi
		rust-analyzer --version
	fi

.PHONY: zellij
zellij: rust # Install zellij, a terminal multiplexer
	cargo install --locked $@
	$@ --version

.PHONY: usage
usage: rust # Install usage, a specification for CLIs
	cargo install usage-cli
	$@ --version

.PHONY: skim
skim: rust # Install skim
	cargo install $@
	sk --version

.PHONY: python
python: mise # Install python
	@name=python
	mise use -g $$name@latest
	pip install --upgrade pip

.PHONY: pgcli
pgcli: python # Install pgcli
	@pip install pgcli

.PHONY: node
node: mise # Install nodejs
	@name=node
	mise use -g $$name@latest

.PHONY: vim
vim: git # Install vim
	@if ! command -v $@ >/dev/null; then
		t=$$(mktemp -d)
		git clone --depth=1 https://github.com/vim/vim.git $$t
		cd "$$t/src"
		sudo make install
		sudo rm -rf $$t
	fi
	$@ --version

.PHONY: vim-language-server
vim-language-server: node # Install vim-language-server
	@npm install -g $@

.PHONY: z
z: git # Install z, jump around
	@if ! command -v $@ >/dev/null; then
		git clone --depth=1 https://github.com/rupa/z ~/z
		sudo cp ~/z/z.1 /usr/local/man/man1
	fi

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
	@docker run --rm -i -v .:/dots -w /dots maketest:v1 bash -s <<EOF
		make base
		make vim
	EOF
