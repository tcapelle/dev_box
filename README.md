# ML DevBox

Development container for ML work on H200 GPUs.

## Setup

1. Set your API keys locally:
```bash
export WANDB_API_KEY=your_key
export ANTHROPIC_API_KEY=your_key
```

2. Start the devbox:
```bash
devpod up . --id tcapelle-ml-box
```

## What's included

**Base image** (`ghcr.io/tcapelle/dev_box`):
- PyTorch 2.9 + CUDA 13.1
- zsh + starship + fzf + eza + zoxide + bat + ripgrep
- neovim with LSP
- uv (fast pip)
- dotfiles pre-configured

**Project dependencies** (installed on startup):
- transformers, diffusers (from git main)
- datasets, accelerate, wandb

## Stop the devbox

Stop when not in use to release GPU resources:
```bash
devpod stop tcapelle-ml-box
```
This deletes the pod (frees GPU) but keeps your data. Run `devpod up` again to resume.

To delete everything (pod + data):
```bash
devpod delete tcapelle-ml-box
```

## Build the image

The Docker image is built automatically on push to main via GitHub Actions.

To build locally:
```bash
docker build -t ghcr.io/tcapelle/dev_box:latest .
```
