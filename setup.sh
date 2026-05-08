#!/bin/bash

# Quick Setup Script
# Makes it easy to get started with Nova cluster

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "  Nova Cluster - Quick Setup"
echo "==========================================${NC}"
echo ""

# Make scripts executable
echo "Making scripts executable..."
chmod +x scripts/*.sh
chmod +x cli/nova
chmod +x gitlab/ci-cd/scripts/*.sh
echo -e "${GREEN}✓${NC} Scripts are now executable"
echo ""

# Check prerequisites
echo "Checking prerequisites..."
MISSING=0

if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} kubectl not found (install from https://kubernetes.io/docs/tasks/tools/)"
    MISSING=$((MISSING+1))
else
    echo -e "${GREEN}✓${NC} kubectl found"
fi

if ! command -v helm &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} helm not found (install from https://helm.sh/docs/intro/install/)"
    MISSING=$((MISSING+1))
else
    echo -e "${GREEN}✓${NC} helm found"
fi

if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} docker not found (optional, for image operations)"
else
    echo -e "${GREEN}✓${NC} docker found"
fi

echo ""

# Setup environment file
if [ ! -f "$ROOT_DIR/.nova-env" ]; then
    echo "Creating .nova-env file..."
    cp "$ROOT_DIR/.nova-env.example" "$ROOT_DIR/.nova-env"
    echo -e "${GREEN}✓${NC} Created .nova-env (edit it to customize)"
    echo ""
fi

# Add CLI to PATH suggestion
echo "To use 'nova' command from anywhere, add to your ~/.bashrc or ~/.zshrc:"
echo ""
echo "  export PATH=\$PATH:$ROOT_DIR/cli"
echo ""
read -p "Add to PATH now? [y/N]: " add_path

if [[ "$add_path" =~ ^[Yy]$ ]]; then
    SHELL_RC=""
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_RC="$HOME/.bashrc"
    fi
    
    if [ -n "$SHELL_RC" ]; then
        if ! grep -q "export PATH.*$ROOT_DIR/cli" "$SHELL_RC"; then
            echo "" >> "$SHELL_RC"
            echo "# Nova CLI" >> "$SHELL_RC"
            echo "export PATH=\$PATH:$ROOT_DIR/cli" >> "$SHELL_RC"
            echo -e "${GREEN}✓${NC} Added to $SHELL_RC"
            echo "Run: source $SHELL_RC"
        else
            echo -e "${GREEN}✓${NC} Already in PATH"
        fi
    fi
fi

echo ""
echo -e "${BLUE}=========================================="
echo "  Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "Quick Start:"
echo "  1. Review documentation:"
echo "     - README.md - Overview"
echo "     - DEVELOPER_GUIDE.md - Developer guide"
echo "     - QUICK_REFERENCE.md - Quick commands"
echo ""
echo "  2. Try the Nova CLI:"
echo "     ./cli/nova help"
echo "     ./cli/nova list"
echo ""
echo "  3. Deploy a component:"
echo "     ./cli/nova deploy postgresql dev"
echo ""
echo "  4. Or use interactive deployment:"
echo "     ./scripts/12-interactive-deploy.sh"
echo ""

if [ $MISSING -gt 0 ]; then
    echo -e "${YELLOW}Note:${NC} Some prerequisites are missing. Install them to use all features."
    echo ""
fi

echo "Happy deploying! 🚀"
