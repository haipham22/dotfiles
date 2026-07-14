# Primary entry is setup.sh (works without make). `make init` wraps it for convenience.
# Run individual phases: make tools | base | chsh | link | inject | submodules
init:       ; @bash "$(CURDIR)/setup.sh"
base:       ; @bash "$(CURDIR)/setup.sh" base
chsh:       ; @bash "$(CURDIR)/setup.sh" chsh
tools:      ; @bash "$(CURDIR)/setup.sh" tools
link:       ; @bash "$(CURDIR)/setup.sh" link
inject:     ; @bash "$(CURDIR)/setup.sh" inject
submodules: ; @bash "$(CURDIR)/setup.sh" submodules

fix-zim:
	@echo "🔧 Fixing zimfw completion issues..."
	@rm -f ~/.zcompdump*
	@if command -v zimfw >/dev/null 2>&1; then \
		zimfw install; \
	fi
	@echo "✅ Done. Run 'exec zsh' to restart shell"
