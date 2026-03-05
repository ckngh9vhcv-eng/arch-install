#!/bin/bash
# =============================================================================
# Void Command Installer — Shared Function Library
# Sourced by install.sh, chroot.sh, and user-setup.sh
# =============================================================================

# Avoid double-sourcing
[[ -n "${_LIB_SH_LOADED:-}" ]] && return 0
_LIB_SH_LOADED=1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# --- Output helpers ---
info()   { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()  { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
header() { echo -e "\n${PURPLE}${BOLD}=== $* ===${NC}\n"; }

# --- ERR trap — catch uncaught failures with context ---
_err_trap() {
    local exit_code=$?
    local line_no=$1
    # If errexit (set -e) is disabled, the caller is handling errors — don't abort
    [[ "$-" =~ e ]] || return 0
    echo -e "${RED}[FATAL]${NC} Command failed at line ${line_no} (exit code ${exit_code})" >&2
    echo -e "${RED}[FATAL]${NC} Script: ${BASH_SOURCE[1]:-unknown}" >&2
    exit "$exit_code"
}
trap '_err_trap ${LINENO}' ERR

# --- run_or_die — run a command, abort with context on failure ---
run_or_die() {
    local desc="$1"
    shift
    info "$desc"
    if ! "$@"; then
        error "$desc — FAILED (command: $*)"
    fi
}

# --- Checkpoint system for re-runnability ---
CHECKPOINT_DIR="/tmp/void-command-checkpoints"
mkdir -p "$CHECKPOINT_DIR"

checkpoint() {
    touch "${CHECKPOINT_DIR}/$1"
}

checkpoint_reached() {
    [[ -f "${CHECKPOINT_DIR}/$1" ]]
}

checkpoint_clear() {
    rm -rf "$CHECKPOINT_DIR"
}

# --- Spinner for long-running operations ---
# Usage: spinner "Installing packages" pacman -S --noconfirm foo bar
spinner() {
    local desc="$1"
    shift

    # If not a terminal (e.g., piped log), just run directly
    if [[ ! -t 1 ]]; then
        info "$desc"
        "$@"
        return
    fi

    local spin_chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local pid

    # Run command in background, capture output to log
    local logfile
    logfile=$(mktemp /tmp/void-cmd-spinner.XXXXXX)
    "$@" > "$logfile" 2>&1 &
    pid=$!

    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        local char="${spin_chars:$((i % ${#spin_chars})):1}"
        printf "\r${GREEN}%s${NC} %s" "$char" "$desc"
        sleep 0.1
        ((i++)) || true
    done

    wait "$pid"
    local exit_code=$?
    printf "\r"  # clear spinner line

    if [[ $exit_code -eq 0 ]]; then
        info "$desc — done"
    else
        echo -e "${RED}[ERROR]${NC} $desc — FAILED (exit code $exit_code)"
        echo -e "${YELLOW}--- Command output ---${NC}"
        cat "$logfile"
        echo -e "${YELLOW}--- End output ---${NC}"
        rm -f "$logfile"
        return $exit_code
    fi
    rm -f "$logfile"
}
