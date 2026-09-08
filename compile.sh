#!/usr/bin/env bash
export PATH="$HOME/.local/bin:$PATH"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
compactc contracts/ZkNumberGuesser.compact managed
