#!/bin/bash
# setup_env.sh: Self-healing bootstrap for Kinetic-Stream-OS
# Usage: source ./scripts/setup_env.sh

# Save current shell options so we can restore them exactly
OLD_OPTS=$(set +o) 

set -euo pipefail

echo "🚀 Starting environment bootstrap for Ubuntu $(lsb_release -rs)..."

# 1. Self-Healing Microsoft Repository Setup
MICROSOFT_GPG="/usr/share/keyrings/microsoft-prod.gpg"
MSSQL_LIST="/etc/apt/sources.list.d/mssql-release.list"
UBUNTU_VER=$(lsb_release -rs)

# Clean up potentially corrupted files from previous failed runs
sudo rm -f "$MSSQL_LIST"

echo "Configuring Microsoft repositories..."
TMP_LIST=$(mktemp)
TMP_KEY=$(mktemp)
trap 'rm -f "$TMP_LIST" "$TMP_KEY"' EXIT

KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"
LIST_URL="https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list"

echo "Fetching keys and repo lists..."
if curl -fsSL "$KEY_URL" -o "$TMP_KEY" && \
   curl -fsSL "$LIST_URL" -o "$TMP_LIST"; then

    # Only move to system folders if downloads were successful
    cat "$TMP_KEY" | sudo gpg --dearmor --yes -o "$MICROSOFT_GPG"
    sudo cp "$TMP_LIST" "$MSSQL_LIST"
    echo "✅ Repositories configured."
else
    echo "❌ Error: Failed to fetch configs from Microsoft. Check your internet or Ubuntu version." >&2
    exit 1
fi

# 2. Update and Install System Dependencies
echo "Installing system dependencies..."
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y \
    msodbcsql18 \
    mssql-tools18 \
    unixodbc-dev \
    libsqlite3-dev

# 3. Virtual Environment Setup
if [ ! -d ".venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv .venv
fi

source .venv/bin/activate
pip install --upgrade pip
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
fi

echo "✅ Bootstrap complete. Run 'source .venv/bin/activate' to begin."

# Check if the script was 'sourced' or 'executed'
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "Transitioning to virtual environment..."
    source .venv/bin/activate
else
    echo "-------------------------------------------------------"
    echo "To enter the environment, run:"
    echo "source .venv/bin/activate"
    echo "-------------------------------------------------------"
fi

# 1. Clean up temp files silently (don't error if they're already gone)
rm -f "$TMP_LIST" "$TMP_KEY" 2>/dev/null

# 2. Clear the trap
trap - EXIT

# 3. Restore original shell options
eval "$OLD_OPTS"

# 4. Final Sanity Check: Verify venv and dependency availability
if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    echo "✔ Active Environment: $(basename "$VIRTUAL_ENV")"
    # Optional: verify a mission-critical tool is available
    if command -v sqlcmd &> /dev/null; then
        echo "✔ MS SQL Tools: Ready"
    fi
else
    echo "⚠️ Warning: Bootstrap finished but virtual environment is not active."
fi

echo ""
echo "🐳 Next steps — start the stack and run the ingestor:"
echo "   docker-compose up -d"
echo "   python3 app/ingestor.py   # MSSQL healthcheck ensures readiness (~20s first boot)"
