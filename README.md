# Dotfiles

Personal configuration files for zsh, git, and development tools.

## Prerequisites

- **Zsh** (default shell on macOS)
- **[zimfw](https://github.com/zimfw/zimfw)** plugin manager
- **[Starship](https://starship.rs/)** prompt
- **[zoxide](https://github.com/ajeetdsouza/zoxide)** smarter cd command
- **[mise](https://mise.jdx.dev/)** version manager (optional)
- **[bun](https://bun.sh/)** JavaScript runtime (optional)

## Quick Start

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/Workspaces/dotfiles
cd ~/Workspaces/dotfiles

# Initialize everything (zsh, gitignore, fix completion issues)
make init

# Restart your shell
exec zsh
```

## Manual Setup

### 1. Link Zsh Configuration

Add to `~/.zshrc`:
```bash
source ~/Workspaces/dotfiles/shell/zsh.sh
```

### 2. Configure zimfw

Create `~/.config/zsh/zimrc` and add modules:
```bash
zmodule environment
zmodule git
zmodule input
zmodule utility
zmodule completion
zmodule zsh-users/zsh-syntax-highlighting
zmodule zsh-users/zsh-history-substring-search
zmodule zsh-users/zsh-autosuggestions
```

Then install:
```bash
zimfw install
```

### 3. Starship Prompt

Starship config is located at `shell/framework/starship.toml`.

Install starship:
```bash
# via cargo
cargo install starship

# via homebrew
brew install starship

# via script
curl -sS https://starship.rs/install.sh | sh
```

### 4. Global Git Ignore

```bash
git config --global core.excludesfile ~/Workspaces/dotfiles/git/.gitignore
```

## Project Structure

```
dotfiles/
├── shell/
│   ├── zsh.sh           # Main shell entry point
│   ├── zim.sh           # Zimfw plugin manager initialization
│   ├── framework/
│   │   └── starship.toml # Starship prompt configuration
│   └── inc/
│       ├── alias.sh     # Command aliases
│       └── functions.sh # Custom functions
├── git/
│   └── .gitignore       # Global git ignores
├── system/
│   └── mac/
│       ├── Brewfile     # Homebrew bundle
│       └── README.md    # macOS-specific docs
├── Makefile            # Installation helpers
└── README.md           # This file
```

## Key Features

### Aliases (shell/inc/alias.sh)

| Tool | Aliases |
|------|---------|
| General | `pn=pnpm`, `ll='ls -l'`, `cls=clear` |
| Git | `gst`, `gpl`, `gph`, `gco`, `gad`, `gcm`, etc. |
| Docker | `dcp=docker compose`, `dcpu`, `dcpud`, `dcpe`, `dcpd` |
| Claude | `ccc`, `cccm` |

### Functions (shell/inc/functions.sh)

- `git_clean_branch` - Delete all local branches except specified one
- `git_empty_commit` - Create and push empty commit
- `node_ver` - Switch Node.js version via pnpm
- `node_ls` - List available Node.js versions
- `clean_ds` - Remove .DS_Store files
- `short_commit` - Get short git commit hash

### Shell Initialization Order

The shell is initialized in this specific order to avoid conflicts:

1. **zimfw** - Plugin manager and completions (must be first)
2. **zoxide** - Smarter directory navigation
3. **aliases/functions** - Custom commands
4. **starship** - Prompt
5. **mise** - Version manager activation
6. **bun** - Runtime and completions

## macOS Setup

See [system/mac/README.md](system/mac/README.md) for macOS-specific setup using Homebrew bundle.

```bash
cd system/mac
brew bundle
```

## Maintenance

### Update zimfw modules
```bash
zimfw update
```

### Upgrade zimfw itself
```bash
zimfw upgrade
```

### Clean zsh cache
```bash
rm -f ~/.zcompdump*
exec zsh
```

### Fix Completion Issues

If you see completion warnings, use the built-in fix function:

```bash
# Via function (diagnoses + fixes)
fix_zim_completion

# Via alias
fix-zim

# Via makefile
make fix-zim
```

This will:
- Check load order of zimfw, zoxide, starship
- Detect duplicate initializations
- Clean .zcompdump cache
- Reinstall zimfw modules

## Troubleshooting

### Completion Warnings

If you see warnings about `compinit` being called multiple times, ensure the initialization order is correct:
- zimfw must load BEFORE any other completion setup (zoxide, mise, bun)
- Check `~/.zshrc` doesn't duplicate `source ~/Workspaces/dotfiles/shell/zsh.sh`

### Starship Not Working

Verify starship is installed and in PATH:
```bash
which starship
starship --version
```

Check the config path:
```bash
echo $STARSHIP_CONFIG
```

## License

MIT