#!/usr/bin/env bash
set -euo pipefail

ROOT="$(dirname "$0")"

pip install -q -r "$ROOT/requirements.txt" 2>/dev/null || true

cd "$ROOT"
exec streamlit run streamlit_app.py
