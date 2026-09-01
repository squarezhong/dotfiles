# Dotfiles

Personal macOS and Ubuntu configuration managed with [chezmoi](https://www.chezmoi.io/). This repository sets up shell, Git, Neovim, and tmux configuration, and installs packages with Homebrew.

## Quick Start

Download and run the bootstrap script on macOS or Ubuntu:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/squarezhong/dotfiles/main/bootstrap.sh)"
```

The script installs the development packages from `Brewfile.dev` on both platforms. On macOS, it also offers to install the optional applications in `Brewfile.life`; the default answer is no.

Follow the prompts to configure your SSH key and Git identity. Ubuntu prerequisites and zsh are installed with `apt-get`, after which zsh is set as the default shell. If macOS asks you to install the Xcode Command Line Tools, complete the installation and run the command again.

Only macOS and Ubuntu are supported. Run the script as a regular user with `sudo` access.

When setup finishes, restart the shell:

```sh
exec zsh -l
```
