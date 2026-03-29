#!/data/data/com.termux/files/usr/bin/bash
#
# install-hermes-proot.sh
# Installs Hermes Agent inside proot-distro Ubuntu on Termux
#
# Usage: bash install-hermes-proot.sh
#
# Handles all scenarios:
#   - Ubuntu already installed -> skip to next step
#   - Hermes already installed -> show "already installed" message
#   - Re-runnable / idempotent at every step
#

# Don't use set -e — we handle errors manually at each step
set +e

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
# Check if Ubuntu is already installed — try multiple detection methods
UBUNTU_INSTALLED=false

# Method 1: Check proot-distro list output (various formats)
if proot-distro list 2>/dev/null | grep -qiE "ubuntu.*installed|installed.*ubuntu"; then
    UBUNTU_INSTALLED=true
fi

# Method 2: Check if the rootfs directory exists
if [ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu" ]; then
    UBUNTU_INSTALLED=true
fi

# Method 3: Try running a command inside ubuntu — if it works, it's installed
if proot-distro login ubuntu -- echo "test" > /dev/null 2>&1; then
    UBUNTU_INSTALLED=true
fi

if [ "$UBUNTU_INSTALLED" = true ]; then
    warn "Ubuntu already installed in proot-distro, skipping install"
else
    info "Installing Ubuntu via proot-distro (this may take a few minutes)..."
    if proot-distro install ubuntu; then
        ok "Ubuntu installed"
    else
        err "Failed to install Ubuntu. Try: proot-distro reset ubuntu"
    fi
fi

# ─── STEP 3: Check if Hermes is already installed ──────────────────────────
HERMES_ALREADY_INSTALLED=false

info "Checking if Hermes Agent is already installed..."

# Check inside proot if hermes binary exists
if proot-distro login ubuntu -- bash -c '
    # Check common locations
    if command -v hermes &>/dev/null; then
        exit 0
    elif [ -f "$HOME/.hermes/hermes-agent/venv/bin/python" ]; then
        exit 0
    elif [ -f "$HOME/.hermes/hermes-agent/venv/bin/hermes" ]; then
        exit 0
    elif [ -d "$HOME/.hermes/hermes-agent" ]; then
        exit 0
    else
        exit 1
    fi
' > /dev/null 2>&1; then
    HERMES_ALREADY_INSTALLED=true
fi

if [ "$HERMES_ALREADY_INSTALLED" = true ]; then
    echo ""
    ok "Hermes Agent is already installed!"
    echo ""
    echo -e "${BOLD}To start Hermes:${NC}"
    echo -e "  ${CYAN}hermes${NC}                 - Start interactive chat"
    echo -e "  ${CYAN}hermes setup${NC}            - Run setup wizard (configure provider + API key)"
    echo -e "  ${CYAN}hermes model${NC}            - Choose your model"
    echo -e "  ${CYAN}hermes doctor${NC}           - Check for issues"
    echo ""

    # Still create/update the launcher in case it's missing
    LAUNCHER="$PREFIX/bin/hermes"
    if [ ! -f "$LAUNCHER" ]; then
        info "Creating Termux launcher..."
        cat > "$LAUNCHER" << 'LAUNCHER_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Launch Hermes inside proot-distro Ubuntu
proot-distro login ubuntu -- bash -c 'source ~/.bashrc 2>/dev/null; hermes "$@"' -- "$@"
LAUNCHER_EOF
        chmod +x "$LAUNCHER"
        ok "Created launcher: you can now type 'hermes' from Termux to launch it"
    fi

    # Ask if user wants to run setup anyway
    echo ""
    echo -e "${YELLOW}[?]${NC} Run ${CYAN}hermes setup${NC} anyway to reconfigure? (y/N)"
    read -r REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        info "Launching Hermes setup wizard..."
        proot-distro login ubuntu -- bash -c 'source ~/.bashrc 2>/dev/null; hermes setup'
    fi

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Nothing to do — Hermes already installed!  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
fi

# ─── STEP 4: Create the inner install script ────────────────────────────────
# This runs INSIDE the proot Ubuntu environment
INNER_SCRIPT="/data/data/com.termux/files/usr/tmp/_hermes_inner_install.sh"

cat > "$INNER_SCRIPT" << 'INNER_EOF'
#!/bin/bash
# No set -e — we handle errors manually
set +e

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

# ─── STEP 4a: System dependencies ───────────────────────────────────────────
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

# ─── STEP 4b: Install Node.js (needed by some Hermes tools) ────────────────
if ! command -v node &> /dev/null; then
    info "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
    apt install -y nodejs > /dev/null 2>&1
    ok "Node.js $(node --version 2>/dev/null) installed"
else
    ok "Node.js already installed: $(node --version)"
fi

# ─── STEP 4c: Check one more time if hermes appeared ────────────────────────
if command -v hermes &>/dev/null || [ -d "$HOME/.hermes/hermes-agent" ]; then
    ok "Hermes Agent detected — skipping install"
else
    # ─── STEP 4d: Run the official Hermes installer ─────────────────────────
    info "Running Hermes Agent installer..."
    echo ""
    if curl -fsSL "$HERMES_INSTALL_SCRIPT" | bash; then
        ok "Hermes Agent installed successfully"
    else
        warn "Hermes installer returned non-zero exit code (may still have installed)"
    fi
    echo ""
fi

# ─── STEP 4e: Verify installation ──────────────────────────────────────────
info "Verifying installation..."

# Source bashrc to get hermes on PATH
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc" 2>/dev/null || true
fi

# Check common locations
INSTALL_OK=false
if command -v hermes &>/dev/null; then
    INSTALL_OK=true
    ok "hermes binary found in PATH"
elif [ -f "$HOME/.hermes/hermes-agent/venv/bin/python" ]; then
    INSTALL_OK=true
    ok "Hermes venv found"
elif [ -f "$HOME/.hermes/hermes-agent/venv/bin/hermes" ]; then
    INSTALL_OK=true
    ok "Hermes binary found in venv"
elif [ -d "$HOME/.hermes/hermes-agent" ]; then
    INSTALL_OK=true
    ok "Hermes directory found"
else
    warn "Could not verify Hermes installation — check manually with: hermes doctor"
fi

# ─── STEP 4f: Print success banner ─────────────────────────────────────────
echo ""
if [ "$INSTALL_OK" = true ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        Installation Complete!                ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
else
    echo -e "${YELLOW}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║   Installation finished with warnings        ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════╝${NC}"
fi
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

# ─── STEP 5: Run inner script inside proot ──────────────────────────────────
info "Entering proot-distro Ubuntu and running setup..."
echo ""

if proot-distro login ubuntu -- bash "$INNER_SCRIPT"; then
    : # success
else
    warn "Inner script exited with non-zero code (some steps may have partially completed)"
fi

# Clean up inner script
rm -f "$INNER_SCRIPT"

# ─── STEP 6: Create a launcher script in Termux ────────────────────────────
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

# ─── STEP 7: Auto-launch setup wizard ───────────────────────────────────────
info "Launching Hermes setup wizard..."
echo ""

proot-distro login ubuntu -- bash -c 'source ~/.bashrc 2>/dev/null; hermes setup'
