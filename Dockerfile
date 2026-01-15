FROM ghcr.io/coreweave/ml-containers/torch-extras:es-cuda-13-dev-4ae9dbb-base-cuda13.1.0-ubuntu22.04-torch2.9.1-vision0.24.1-audio2.9.1-abi1

# Remove apex (causes bfloat16 issues)
RUN pip uninstall apex -y || true

# Dotfiles dependencies
RUN apt-get update && apt-get install -y zsh fzf bat ripgrep neovim && rm -rf /var/lib/apt/lists/*

# Install starship
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

# Install zoxide
RUN curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# Install eza
RUN wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list && \
    apt-get update && apt-get install -y eza && rm -rf /var/lib/apt/lists/*

# Install uv
RUN pip install uv

# Dotfiles
RUN rm -f ~/.bashrc ~/.gitconfig && \
    git clone --recursive https://github.com/tcapelle/dotfiles.git ~/.dotfiles && \
    cd ~/.dotfiles && ./install || true

# Set zsh as default shell
RUN chsh -s $(which zsh) || true

# Add local bin to PATH
ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /workspaces
