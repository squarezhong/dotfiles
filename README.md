# Dotfiles

Personal macOS configuration managed with [chezmoi](https://www.chezmoi.io/). This repository sets up shell, Git, Neovim, and tmux configuration, and installs a selectable set of Homebrew packages.

## Quick Start

Download and run the bootstrap script on a new Mac:

```sh
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/squarezhong/dotfiles/main/bootstrap.sh)"
```

Follow the prompts to configure your SSH key and Git identity, then choose either the full or development Homebrew package set. If macOS asks you to install the Xcode Command Line Tools, complete the installation and run the commands again.

When setup finishes, restart the shell:

```sh
exec zsh -l
```
