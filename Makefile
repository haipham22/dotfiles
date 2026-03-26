init-git:
	git submodule update --recursive --init

init:
	make init-zsh
	make init-gitignore
	make fix-zim


init-zsh:
	echo "source $$(pwd)/shell/zsh.sh" >> ~/.zshrc


init-gitignore:
	git config --global core.excludesfile "$$(pwd)/git/.gitignore"


fix-zim:
	@echo "🔧 Fixing zimfw completion issues..."
	@rm -f ~/.zcompdump*
	@if command -v zimfw >/dev/null 2>&1; then \
		zimfw install; \
	fi
	@echo "✅ Done. Run 'exec zsh' to restart shell"
