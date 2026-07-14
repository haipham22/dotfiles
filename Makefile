# Primary entry is setup.sh (works without make). `make init` wraps it for convenience.
init:
	@bash "$(CURDIR)/setup.sh"

fix-zim:
	@echo "🔧 Fixing zimfw completion issues..."
	@rm -f ~/.zcompdump*
	@if command -v zimfw >/dev/null 2>&1; then \
		zimfw install; \
	fi
	@echo "✅ Done. Run 'exec zsh' to restart shell"
