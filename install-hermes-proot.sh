#!/data/data/com.termux/files/usr/bin/bash
#
# install-hermes-proot.sh
# Installs Hermes Agent inside proot-distro Ubuntu on Termux
#
# Usage: bash install-hermes-proot.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}[*]${NC} $1"; }
ok()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
err()   { echo -e "${RED}[✗]${NC} $1"; exit 1; }

HERMES_INSTALL_SCRIPT="https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh"

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   Hermes Agent - proot-distro Ubuntu Setup  ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ─── STEP 1: Termux prerequisites ───────────────────────────────────────────
info "Updating Termux packages..."
pkg update -y > /dev/null 2>&1
ok "Termux packages updated"

info "Installing Termux dependencies..."
pkg install -y proot-distro git curl > /dev/null 2>&1
ok "Termux dependencies installed"

# ─── STEP 2: proot-distro Ubuntu ────────────────────────────────────────────
# Check if Ubuntu is already installed
if proot-distro list 2>/dev/null | grep -q "ubuntu.*installed"; then
    warn "Ubuntu already installed in proot-distro, skipping install"
else
    info "Installing Ubuntu via proot-distro (this may take a few minutes)..."
    proot-distro install ubuntu
    ok "Ubuntu installed"
fi

# ─── STEP 3: Create the inner install script ────────────────────────────────
# This runs INSIDE the proot Ubuntu environment
INNER_SCRIPT="/data/data/com.termux/files/usr/tmp/_hermes_inner_install.sh"

cat > "$INNER_SCRIPT" << 'INNER_EOF'
#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}[*]${NC} $1"; }
ok()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }

HERMES_INSTALL_SCRIPT="https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh"

echo ""
echo -e "${BOLD}── Inside proot-distro Ubuntu ──${NC}"
echo ""

# ─── STEP 3a: System dependencies ───────────────────────────────────────────
info "Updating Ubuntu packages..."
apt update > /dev/null 2>&1

info "Installing system dependencies..."
DEBIAN_FRONTEND=noninteractive apt install -y \
    git \
    curl \
    wget \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    libffi-dev \
    libssl-dev \
    ca-certificates \
    gnupg \
    unzip \
    > /dev/null 2>&1
ok "System dependencies installed"

# ─── STEP 3b: Install Node.js (needed by some Hermes tools) ────────────────
if ! command -v node &> /dev/null; then
    info "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
    apt install -y nodejs > /dev/null 2>&1
    ok "Node.js $(node --version) installed"
else
    ok "Node.js already installed: $(node --version)"
fi

# ─── STEP 3c: Run the official Hermes installer ────────────────────────────
info "Running Hermes Agent installer..."
echo ""
curl -fsSL "$HERMES_INSTALL_SCRIPT" | bash
echo ""
ok "Hermes Agent installed"

# ─── STEP 3d: Verify installation ──────────────────────────────────────────
info "Verifying installation..."

# Source bashrc to get hermes on PATH
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc" 2>/dev/null || true
fi

# Also try the common install location
if [ -f "$HOME/.hermes/hermes-agent/venv/bin/python" ]; then
    ok "Hermes venv found"
else
    warn "Hermes venv not found at expected location, but continuing..."
fi

# ─── STEP 3e: Print success banner ─────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Installation Complete!                ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}To start Hermes:${NC}"
echo -e "  ${CYAN}hermes${NC}                 - Start interactive chat"
echo -e "  ${CYAN}hermes setup${NC}            - Run setup wizard (configure provider + API key)"
echo -e "  ${CYAN}hermes model${NC}            - Choose your model"
echo -e "  ${CYAN}hermes doctor${NC}           - Check for issues"
echo ""
echo -e "${BOLD}First time?${NC} Run ${CYAN}hermes setup${NC} to configure your provider and API key."
echo ""

INNER_EOF

chmod +x "$INNER_SCRIPT"

# ─── STEP 4: Run inner script inside proot ──────────────────────────────────
info "Entering proot-distro Ubuntu and running setup..."
echo ""

proot-distro login ubuntu -- bash "$INNER_SCRIPT"

# Clean up inner script
rm -f "$INNER_SCRIPT"

# ─── STEP 5: Create a launcher script in Termux ────────────────────────────
LAUNCHER="$PREFIX/bin/hermes"
cat > "$LAUNCHER" << 'LAUNCHER_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Launch Hermes inside proot-distro Ubuntu
proot-distro login ubuntu -- bash -c 'source ~/.bashrc 2>/dev/null; hermes "$@"' -- "$@"
LAUNCHER_EOF
chmod +x "$LAUNCHER"

ok "Created launcher: you can now type 'hermes' from Termux to launch it"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   All done! Run 'hermes setup' to configure  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ─── STEP 6: Auto-launch setup wizard ───────────────────────────────────────
info "Launching Hermes setup wizard..."
echo ""

proot-distro login ubuntu -- bash -c 'source ~/.bashrc 2>/dev/null; hermes setup'
