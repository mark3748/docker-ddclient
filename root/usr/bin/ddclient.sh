#!/bin/sh
##########################################################
##      Modern init script for docker ddclient          ##
## Enhanced with proper error handling, logging, and    ##
## signal management for graceful shutdown              ##
##########################################################

set -eu  # Exit on error, undefined vars (sh doesn't support pipefail)

# Global variables
readonly SCRIPT_NAME="$(basename "$0")"
readonly PID_FILE="/var/run/ddclient/ddclient.pid"
readonly CONFIG_FILE="/etc/ddclient/ddclient.conf"
readonly USER_CONFIG_FILE="/config/ddclient.conf"
readonly DEFAULT_CONFIG_FILE="/defaults/ddclient.conf"
readonly LOG_PREFIX="ddclient-docker"

# Logging functions
log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$LOG_PREFIX] INFO: $*" >&2
}

log_warn() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$LOG_PREFIX] WARN: $*" >&2
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$LOG_PREFIX] ERROR: $*" >&2
}

# Signal handlers for graceful shutdown
cleanup() {
    local exit_code=$?
    log_info "Received shutdown signal, cleaning up..."
    
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            log_info "Stopping ddclient process (PID: $pid)"
            kill -TERM "$pid" 2>/dev/null || true
            # Wait up to 10 seconds for graceful shutdown
            # Wait up to 10 seconds for graceful shutdown
            i=1
            while [ $i -le 10 ] && kill -0 "$pid" 2>/dev/null; do
                sleep 1
                i=$((i + 1))
            done
            # Force kill if still running
            if kill -0 "$pid" 2>/dev/null; then
                log_warn "Force killing ddclient process"
                kill -KILL "$pid" 2>/dev/null || true
            fi
        fi
        rm -f "$PID_FILE"
    fi
    
    log_info "Cleanup completed"
    exit $exit_code
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT SIGQUIT

# Validate configuration file
validate_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    if [ ! -r "$config_file" ]; then
        log_error "Configuration file not readable: $config_file"
        return 1
    fi
    
    # Basic syntax check
    if ! /usr/bin/ddclient -file "$config_file" -query >/dev/null 2>&1; then
        log_error "Configuration file validation failed: $config_file"
        return 1
    fi
    
    log_info "Configuration file validated: $config_file"
    return 0
}

# Extract daemon interval from config
get_daemon_interval() {
    local config_file="$1"
    local interval
    
    # More robust parsing with proper error handling
    if interval=$(grep -E '^[[:space:]]*daemon[[:space:]]*=' "$config_file" 2>/dev/null | \
                 sed -E 's/^[[:space:]]*daemon[[:space:]]*=[[:space:]]*([0-9]+).*/\1/' | \
                 head -1); then
        
        if [ -n "$interval" ] && [ "$interval" -gt 0 ]; then
            echo "$interval"
            return 0
        fi
    fi
    
    # Default to 5 minutes if not found or invalid
    echo "300"
    return 0
}

# Initialize directories and permissions
init_directories() {
    log_info "Initializing directories and permissions"
    
    # Directories should already exist with correct ownership from Dockerfile
    # But ensure they're accessible
    if [ ! -d "/var/cache/ddclient" ] || [ ! -w "/var/cache/ddclient" ]; then
        log_error "Cache directory not accessible: /var/cache/ddclient"
        return 1
    fi
    
    if [ ! -d "/var/run/ddclient" ] || [ ! -w "/var/run/ddclient" ]; then
        log_error "Runtime directory not accessible: /var/run/ddclient"
        return 1
    fi
    
    log_info "Directory permissions verified"
    return 0
}

# Setup configuration
setup_config() {
    log_info "Setting up configuration"
    
    # Copy default config if user config doesn't exist
    if [ ! -e "$USER_CONFIG_FILE" ]; then
        if [ -f "$DEFAULT_CONFIG_FILE" ]; then
            log_info "Copying default configuration to $USER_CONFIG_FILE"
            cp "$DEFAULT_CONFIG_FILE" "$USER_CONFIG_FILE" || {
                log_error "Failed to copy default configuration"
                return 1
            }
        else
            log_error "Default configuration file not found: $DEFAULT_CONFIG_FILE"
            return 1
        fi
    fi
    
    # Copy user config to expected location for ddclient v4.0.0
    log_info "Using configuration: $USER_CONFIG_FILE"
    cp "$USER_CONFIG_FILE" "$CONFIG_FILE" || {
        log_error "Failed to copy configuration to $CONFIG_FILE"
        return 1
    }
    
    # Validate configuration
    validate_config "$CONFIG_FILE" || return 1
    
    log_info "Configuration setup completed"
    return 0
}

# Main execution function
run_ddclient() {
    local timer
    timer=$(get_daemon_interval "$CONFIG_FILE")
    
    log_info "Starting ddclient daemon loop (interval: ${timer}s)"
    
    while true; do
        log_info "Running ddclient update"
        
        # Run ddclient with proper error handling
        if /usr/bin/ddclient -foreground -daemon=0 -noquiet -file "$CONFIG_FILE"; then
            log_info "ddclient update completed successfully"
        else
            local exit_code=$?
            log_error "ddclient update failed with exit code: $exit_code"
            # Continue running even if update fails
        fi
        
        log_info "Sleeping for ${timer} seconds until next update"
        sleep "$timer" &
        wait $!  # Wait for sleep but allow signal interruption
    done
}

# Main execution
main() {
    log_info "Starting $SCRIPT_NAME"
    log_info "ddclient version: $(/usr/bin/ddclient --version 2>&1 | head -1 || echo 'unknown')"
    
    # Initialize
    init_directories || exit 1
    setup_config || exit 1
    
    # Start main loop
    run_ddclient
}

# Execute main function
main "$@"