#!/usr/bin/env bash

set -euo pipefail

DOTFILES_REPO="https://github.com/squarezhong/dotfiles.git"
NVM_VERSION="v0.40.7"

die() {
	echo "Error: $*" >&2
	exit 1
}

detect_platform() {
	case "$(uname -s)" in
	Darwin)
		PLATFORM="macos"
		case "$(uname -m)" in
		arm64) HOMEBREW_PREFIX="/opt/homebrew" ;;
		x86_64) HOMEBREW_PREFIX="/usr/local" ;;
		*) die "Unsupported macOS architecture: $(uname -m)" ;;
		esac
		;;
	Linux)
		[[ -r /etc/os-release ]] || die "Only macOS and Ubuntu are supported."
		# shellcheck disable=SC1091
		. /etc/os-release
		[[ "${ID:-}" == "ubuntu" ]] ||
			die "Only macOS and Ubuntu are supported (detected: ${PRETTY_NAME:-Linux})."
		PLATFORM="ubuntu"
		HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
		;;
	*)
		die "Only macOS and Ubuntu are supported (detected: $(uname -s))."
		;;
	esac
}

install_ubuntu_prerequisites() {
	local -a packages=(
		build-essential
		procps
		curl
		file
		git
		openssh-client
		zsh
	)

	echo
	echo "Installing Ubuntu prerequisites..."
	sudo apt-get update
	sudo apt-get install -y "${packages[@]}"

	local zsh_path current_shell passwd_entry
	zsh_path="$(command -v zsh)"
	passwd_entry="$(getent passwd "$(id -un)")"
	current_shell="${passwd_entry##*:}"

	if [[ "$current_shell" != "$zsh_path" ]]; then
		echo
		echo "Setting zsh as the default shell..."
		chsh -s "$zsh_path"
	else
		echo "zsh is already the default shell, skipping."
	fi
}

install_brewfile() {
	local brewfile="$1"

	[[ -f "$brewfile" ]] || die "Brewfile not found: $brewfile"

	echo
	echo "Installing Homebrew packages from:"
	echo "  $brewfile"
	echo
	brew bundle --file="$brewfile"
}

confirm_life_packages() {
	local reply

	while true; do
		read -r -p "Install optional macOS packages from Brewfile.life? [y/N] " reply || {
			echo
			return 1
		}

		case "${reply:-n}" in
		[Yy]) return 0 ;;
		[Nn]) return 1 ;;
		*) echo "Please enter y or n." ;;
		esac
	done
}

detect_platform

if ((EUID == 0)); then
	die "Run this script as a regular user, not as root."
fi

# ============================================================
# 1. Platform prerequisites
# ============================================================

if [[ "$PLATFORM" == "macos" ]]; then
	if ! xcode-select -p >/dev/null 2>&1; then
		echo "Installing Xcode Command Line Tools..."
		xcode-select --install

		echo
		echo "Complete the Command Line Tools installation,"
		echo "then run this script again."
		exit 0
	fi
else
	install_ubuntu_prerequisites
fi

# ============================================================
# 2. SSH key
# ============================================================

if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
	echo
	read -r -p "SSH key comment: " SSH_COMMENT

	mkdir -p "$HOME/.ssh"
	chmod 700 "$HOME/.ssh"

	ssh-keygen \
		-t ed25519 \
		-a 256 \
		-C "$SSH_COMMENT"
else
	echo "SSH key already exists, skipping."
fi

# ============================================================
# 3. Homebrew
# ============================================================

if command -v brew >/dev/null 2>&1; then
	BREW_BIN="$(command -v brew)"
else
	echo
	echo "Installing Homebrew..."

	/bin/bash -c \
		"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	BREW_BIN="$HOMEBREW_PREFIX/bin/brew"
fi

[[ -x "$BREW_BIN" ]] || die "Homebrew installation not found at $BREW_BIN"
eval "$("$BREW_BIN" shellenv)"

# ============================================================
# 4. chezmoi
# ============================================================

if ! command -v chezmoi >/dev/null 2>&1; then
	echo
	echo "Installing chezmoi..."
	brew install chezmoi
fi

if ! CHEZMOI_SOURCE="$(chezmoi source-path 2>/dev/null)" ||
	[[ ! -d "$CHEZMOI_SOURCE" ]]; then
	echo
	echo "Initializing dotfiles..."
	chezmoi init "$DOTFILES_REPO"
	CHEZMOI_SOURCE="$(chezmoi source-path)"
else
	echo "chezmoi source directory already exists, skipping init."
fi

# ============================================================
# 5. Homebrew packages
# ============================================================

install_brewfile "$CHEZMOI_SOURCE/Brewfile.dev"

if [[ "$PLATFORM" == "macos" ]] && confirm_life_packages; then
	install_brewfile "$CHEZMOI_SOURCE/Brewfile.life"
fi

# ============================================================
# 6. Oh My Zsh
# ============================================================

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
	echo
	echo "Installing Oh My Zsh..."

	RUNZSH=no \
		CHSH=no \
		sh -c \
		"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
	echo "Oh My Zsh already exists, skipping."
fi

# ============================================================
# 7. nvm
# ============================================================

if [[ ! -d "$HOME/.nvm" ]]; then
	echo
	echo "Installing nvm..."

	PROFILE=/dev/null \
		curl -o- \
		"https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" |
		bash
else
	echo "nvm already exists, skipping."
fi

# ============================================================
# 8. Apply dotfiles
# ============================================================

echo
echo "Applying dotfiles..."
chezmoi apply

echo
echo "Bootstrap complete."
echo
echo "Restart your shell with:"
echo
echo "  exec zsh -l"
echo
