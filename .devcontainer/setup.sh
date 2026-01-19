#!/bin/bash
set -e
set -o pipefail

# Install project dependencies
uv pip install --system -e .

# install codex
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi

# shellcheck disable=SC1090
. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts

npm i -g @openai/codex

echo "Done!"
