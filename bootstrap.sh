#!/bin/zsh

set -e

DOTFILES_REPO="https://github.com/squarezhong/dotfiles.git"
NVM_VERSION="v0.40.7"

# ============================================================
# 1. Xcode Command Line Tools
# ============================================================

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install

  echo
  echo "Complete the Command Line Tools installation,"
  echo "then run this script again."
  exit 0
fi

# ============================================================
# 2. SSH key
# ============================================================

if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  echo
  read "SSH_COMMENT?SSH key comment: "

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

if ! command -v brew >/dev/null 2>&1; then
  echo
  echo "Installing Homebrew..."

  /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# ============================================================
# 4. Load Homebrew into current shell
# ============================================================

if [[ -x /opt/homebrew/bin/brew ]]; then
  # Apple Silicon
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  # Intel Mac
  eval "$(/usr/local/bin/brew shellenv)"
else
  echo "Error: Homebrew installation not found."
  exit 1
fi

# ============================================================
# 5. Install chezmoi
# ============================================================

if ! command -v chezmoi >/dev/null 2>&1; then
  echo
  echo "Installing chezmoi..."
  brew install chezmoi
fi

# ============================================================
# 6. Initialize dotfiles
# ============================================================

if [[ ! -d "$(chezmoi source-path 2>/dev/null)" ]]; then
  echo
  echo "Initializing dotfiles..."

  chezmoi init "$DOTFILES_REPO"
else
  echo "chezmoi source directory already exists, skipping init."
fi

CHEZMOI_SOURCE="$(chezmoi source-path)"

# ============================================================
# 7. Select Brewfile
# ============================================================

echo
echo "Select Homebrew environment:"
echo
echo "  1) Full        (Brewfile)"
echo "  2) Development (Brewfile.dev) [default]"
echo

while true; do
  read "BREWFILE_CHOICE?Enter choice [1/2] (default: 2): "

  BREWFILE_CHOICE="${BREWFILE_CHOICE:-2}"

  case "$BREWFILE_CHOICE" in
  1)
    BREWFILE="$CHEZMOI_SOURCE/Brewfile"
    break
    ;;
  2)
    BREWFILE="$CHEZMOI_SOURCE/Brewfile.dev"
    break
    ;;
  *)
    echo "Invalid choice. Please enter 1 or 2."
    ;;
  esac
done

if [[ ! -f "$BREWFILE" ]]; then
  echo "Error: Brewfile not found:"
  echo "  $BREWFILE"
  exit 1
fi

echo
echo "Installing Homebrew packages from:"
echo "  $BREWFILE"
echo

brew bundle --file="$BREWFILE"

# ============================================================
# 8. Oh My Zsh
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
# 9. nvm
# ===============[118;1:3u=============================================

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
# 10. Apply dotfiles
# ============================================================

echo
echo "Applying dotfiles..."

chezmoi apply

# ============================================================
# Done
# ============================================================

echo
echo "Bootstrap complete."
echo
echo "Restart your shell with:"
echo
echo "  exec zsh -l"
echo
