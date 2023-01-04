init-git:
	git submodule update --recursive --init

init:
	make init-zsh
	make init-gitignore


init-zsh:
	echo "source $$(pwd)/shell/zsh.sh" >> ~/.zshrc


init-gitignore:
	git config --global core.excludesfile "$$(pwd)/git/.gitignore"
