#!/usr/bin/env bash
set -euo pipefail

# ── Config ───────────────────────────────────────────────────
DB_NAME="${DB_NAME:-surgery_department}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
SQL_DIR="$(dirname "$0")/sql"

export DB_NAME DB_USER DB_PASSWORD DB_HOST DB_PORT

# ── Help ─────────────────────────────────────────────────────
usage() {
    echo "Usage: $0 [--seed-only | --app-only | --reset]"
    echo ""
    echo "  (default)   Create DB → schema → seed → run app"
    echo "  --seed-only Create DB → schema → seed (stop)"
    echo "  --app-only  Run app only (assumes DB ready)"
    echo "  --reset     Drop & recreate DB → schema → seed → run app"
    exit 0
}

MODE="${1:-full}"
case "$MODE" in
    --help|-h) usage ;;
    --seed-only) MODE="seed-only" ;;
    --app-only)  MODE="app-only" ;;
    --reset)     MODE="reset" ;;
    full)        MODE="full" ;;
    *)           echo "Unknown option: $1"; usage ;;
esac

# ── Check prerequisites ─────────────────────────────────────
command -v psql >/dev/null 2>&1 || { echo "ERROR: psql not found"; exit 1; }
command -v streamlit >/dev/null 2>&1 || { echo "ERROR: streamlit not found — pip install -r requirements.txt"; exit 1; }

# ── DB connection string (without dbname for server ops) ────
export PGPASSWORD="$DB_PASSWORD"
SERVER_URI="postgresql://${DB_USER}@${DB_HOST}:${DB_PORT}/postgres"
DB_URI="postgresql://${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

# ── Reset (drop & recreate) ─────────────────────────────────
if [ "$MODE" = "reset" ]; then
    echo "=== Dropping database $DB_NAME ==="
    psql "$SERVER_URI" -c "DROP DATABASE IF EXISTS ${DB_NAME};" 2>/dev/null || true
    echo "=== Creating database $DB_NAME ==="
    psql "$SERVER_URI" -c "CREATE DATABASE ${DB_NAME};"
    MODE="full"
fi

# ── Create DB if not exists ─────────────────────────────────
if [ "$MODE" = "full" ] || [ "$MODE" = "seed-only" ]; then
    echo "=== Creating database $DB_NAME (if not exists) ==="
    psql "$SERVER_URI" -tc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}';" \
        | grep -q 1 || psql "$SERVER_URI" -c "CREATE DATABASE ${DB_NAME};"

    echo "=== Running schema.sql ==="
    psql "$DB_URI" -f "$SQL_DIR/schema.sql"

    echo "=== Running seed.sql ==="
    psql "$DB_URI" -f "$SQL_DIR/seed.sql"

    echo "=== DB ready ==="
    if [ "$MODE" = "seed-only" ]; then
        exit 0
    fi
fi

# ── Run Streamlit app ───────────────────────────────────────
echo "=== Starting Streamlit app ==="
cd "$(dirname "$0")"
exec streamlit run streamlit_app.py
