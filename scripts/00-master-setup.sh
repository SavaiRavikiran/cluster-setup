#!/bin/bash

# Script: 00-master-setup.sh
# Description: Master script to run all setup steps in order
# Usage: ./00-master-setup.sh [--skip-prereq] [--skip-network] [--skip-core] [--skip-gitlab] [--skip-monitoring] [--skip-novaridium]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Parse arguments
SKIP_PREREQ=false
SKIP_NETWORK=false
SKIP_CORE=false
SKIP_GITLAB=false
SKIP_MONITORING=false
SKIP_NOVARIDIUM=false

for arg in "$@"; do
    case $arg in
        --skip-prereq)
            SKIP_PREREQ=true
            shift
            ;;
        --skip-network)
            SKIP_NETWORK=true
            shift
            ;;
        --skip-core)
            SKIP_CORE=true
            shift
            ;;
        --skip-gitlab)
            SKIP_GITLAB=true
            shift
            ;;
        --skip-monitoring)
            SKIP_MONITORING=true
            shift
            ;;
        --skip-novaridium)
            SKIP_NOVARIDIUM=true
            shift
            ;;
        *)
            ;;
    esac
done

echo "=========================================="
echo "Kubernetes Cluster Infrastructure Setup"
echo "=========================================="
echo ""

# Function to run script
run_script() {
    local script_name=$1
    local script_path="$SCRIPT_DIR/$script_name"
    
    if [ ! -f "$script_path" ]; then
        echo -e "${RED}Error: Script $script_name not found${NC}"
        exit 1
    fi
    
    if [ ! -x "$script_path" ]; then
        chmod +x "$script_path"
    fi
    
    echo -e "${GREEN}Running $script_name...${NC}"
    echo "----------------------------------------"
    "$script_path"
    echo ""
}

# 1. Prerequisites Check
if [ "$SKIP_PREREQ" = false ]; then
    run_script "01-prerequisites-check.sh"
    echo "Press Enter to continue or Ctrl+C to abort..."
    read
else
    echo -e "${YELLOW}Skipping prerequisites check${NC}"
fi

# 2. Network Setup
if [ "$SKIP_NETWORK" = false ]; then
    run_script "02-network-setup.sh"
    echo "Press Enter to continue or Ctrl+C to abort..."
    read
else
    echo -e "${YELLOW}Skipping network setup${NC}"
fi

# 3. Core Infrastructure
if [ "$SKIP_CORE" = false ]; then
    run_script "03-core-infra-setup.sh"
    echo "Press Enter to continue or Ctrl+C to abort..."
    read
else
    echo -e "${YELLOW}Skipping core infrastructure setup${NC}"
fi

# 4. GitLab Setup
if [ "$SKIP_GITLAB" = false ]; then
    run_script "04-gitlab-setup.sh"
    echo "Press Enter to continue or Ctrl+C to abort..."
    read
else
    echo -e "${YELLOW}Skipping GitLab setup${NC}"
fi

# 5. Monitoring Setup
if [ "$SKIP_MONITORING" = false ]; then
    run_script "05-monitoring-setup.sh"
    echo "Press Enter to continue or Ctrl+C to abort..."
    read
else
    echo -e "${YELLOW}Skipping monitoring setup${NC}"
fi

# 6. Novaridium Components
if [ "$SKIP_NOVARIDIUM" = false ]; then
    run_script "06-novaridium-setup.sh"
    echo "Press Enter to continue or Ctrl+C to abort..."
    read
else
    echo -e "${YELLOW}Skipping Novaridium components setup${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}All setup scripts completed!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Review and update all configuration files in the values/ directories"
echo "2. Configure proxy settings if required"
echo "3. Update passwords and secrets"
echo "4. Deploy components using the provided helm/kubectl commands"
echo ""
echo "For detailed instructions, see README.md"
