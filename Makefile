init-git:
	git submodule update --recursive --init

init:
	echo "source $$(pwd)/shell/zsh.sh" >> ~/.zshrc
