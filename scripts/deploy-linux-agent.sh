#!/bin/bash
# ================================================================
#  Wazuh Linux Agent Deployment Script
#  Project: SIEM Deployment & Analysis
#  Author:  Muhammad Ahmad | 25I-7705
#
#  Usage: sudo bash deploy-linux-agent.sh <MANAGER_IP> <AGENT_NAME>
#  Example: sudo bash deploy-linux-agent.sh 192.168.134.129 linux-endpoint
# ================================================================

set -euo pipefail

# ────────────────────────────────────────────────────────────────
# CONFIGURATION — Edit these values
# ────────────────────────────────────────────────────────────────
WAZUH_VERSION="4.14.4-1"
MANAGER_IP="${1:-192.168.134.129}"
AGENT_NAME="${2:-linux-agent}"
ARCH="amd64"

# ────────────────────────────────────────────────────────────────
# COLORS
# ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ────────────────────────────────────────────────────────────────
# FUNCTIONS
# ────────────────────────────────────────────────────────────────
print_banner() {
  echo -e "${CYAN}"
  echo "  ██╗    ██╗ █████╗ ███████╗██╗   ██╗██╗  ██╗"
  echo "  ██║    ██║██╔══██╗╚══███╔╝██║   ██║██║  ██║"
  echo "  ██║ █╗ ██║███████║  ███╔╝ ██║   ██║███████║"
  echo "  ██║███╗██║██╔══██║ ███╔╝  ██║   ██║██╔══██║"
  echo "  ╚███╔███╔╝██║  ██║███████╗╚██████╔╝██║  ██║"
  echo "   ╚══╝╚══╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝"
  echo -e "${NC}"
  echo -e "${BOLD}  Linux Agent Deployment Script${NC}"
  echo -e "  Manager: ${YELLOW}${MANAGER_IP}${NC}  |  Agent: ${YELLOW}${AGENT_NAME}${NC}"
  echo ""
}

log_info()    { echo -e "${GREEN}[+]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
log_error()   { echo -e "${RED}[-]${NC} $1"; }
log_section() { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${BOLD} $1${NC}"; echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

check_root() {
  if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root. Use: sudo bash $0"
    exit 1
  fi
}

check_connectivity() {
  log_section "Checking Connectivity"
  if ping -c 1 "${MANAGER_IP}" &>/dev/null; then
    log_info "Manager at ${MANAGER_IP} is reachable"
  else
    log_warn "Cannot ping Manager IP ${MANAGER_IP}. Continuing anyway..."
  fi
}

remove_existing_agent() {
  log_section "Removing Existing Wazuh Installation (if any)"
  if dpkg -l | grep -q wazuh-agent 2>/dev/null; then
    log_warn "Existing wazuh-agent found. Removing..."
    systemctl stop wazuh-agent 2>/dev/null || true
    apt-get remove --purge wazuh-agent -y 2>/dev/null || true
    log_info "Old agent removed"
  else
    log_info "No existing wazuh-agent found"
  fi
}

install_agent() {
  log_section "Downloading & Installing Wazuh Agent v${WAZUH_VERSION}"

  local deb_file="wazuh-agent_${WAZUH_VERSION}_${ARCH}.deb"
  local download_url="https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/${deb_file}"

  log_info "Downloading from: ${download_url}"
  wget -q --show-progress "${download_url}" -O "/tmp/${deb_file}"

  log_info "Installing with MANAGER=${MANAGER_IP}, AGENT_NAME=${AGENT_NAME}"
  WAZUH_MANAGER="${MANAGER_IP}" \
  WAZUH_AGENT_NAME="${AGENT_NAME}" \
  WAZUH_PROTOCOL="tcp" \
    dpkg -i "/tmp/${deb_file}"

  log_info "Agent installed successfully"
}

start_agent() {
  log_section "Starting Wazuh Agent Service"

  systemctl daemon-reload
  systemctl enable wazuh-agent
  systemctl start wazuh-agent

  sleep 3

  if systemctl is-active --quiet wazuh-agent; then
    log_info "Wazuh Agent is ACTIVE and running"
  else
    log_error "Wazuh Agent failed to start. Check: journalctl -u wazuh-agent"
    exit 1
  fi
}

verify_connection() {
  log_section "Verifying Agent Connection"
  log_info "Agent status:"
  systemctl status wazuh-agent --no-pager | grep -E "Active:|Main PID:"
  echo ""
  log_info "Check the Wazuh Dashboard → Agents section to verify 'Active' status"
  log_info "Dashboard URL: https://${MANAGER_IP}"
}

cleanup() {
  log_info "Cleaning up temporary files..."
  rm -f "/tmp/wazuh-agent_${WAZUH_VERSION}_${ARCH}.deb"
}

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────
main() {
  print_banner
  check_root
  check_connectivity
  remove_existing_agent
  install_agent
  start_agent
  verify_connection
  cleanup

  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD} ✅ Wazuh Agent Deployment Complete!${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "  Manager IP:   ${YELLOW}${MANAGER_IP}${NC}"
  echo -e "  Agent Name:   ${YELLOW}${AGENT_NAME}${NC}"
  echo -e "  Dashboard:    ${CYAN}https://${MANAGER_IP}${NC}"
  echo ""
}

main "$@"
