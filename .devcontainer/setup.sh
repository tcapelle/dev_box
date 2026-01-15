#!/bin/bash
set -e

# Install project dependencies
uv pip install --system -e .

echo "Done!"
