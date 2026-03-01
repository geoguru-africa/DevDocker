#!/bin/bash
# Test SSH connectivity to DevDocker container
# This script verifies that SSH is properly configured and accessible

set -e

SSH_PORT="${SSH_PORT:-2222}"
SSH_KEY=""
MAX_RETRIES=5
RETRY_DELAY=2

echo "=== Testing SSH Connection to DevDocker ==="
echo ""

# Check if container is running
if ! docker ps | grep -q devdocker; then
    echo "ERROR: DevDocker container is not running"
    echo "Start it with: docker-compose up -d"
    exit 1
fi

echo "✓ Container is running"

# Detect SSH key to use
if [ -f ./ssh-keys/authorized_keys ]; then
    echo "✓ SSH keys configured in ./ssh-keys/authorized_keys"
    
    # Detect SSH directory (handle Windows paths)
    if [ -d "$HOME/.ssh" ]; then
        SSH_DIR="$HOME/.ssh"
    elif [ -d "/c/Users/$USER/.ssh" ]; then
        SSH_DIR="/c/Users/$USER/.ssh"
    elif [ -n "$USERPROFILE" ] && [ -d "$(cygpath -u "$USERPROFILE")/.ssh" 2>/dev/null ]; then
        SSH_DIR="$(cygpath -u "$USERPROFILE")/.ssh"
    else
        SSH_DIR="$HOME/.ssh"
    fi
    
    # Find all private keys in SSH directory (matching setup-ssh-keys.sh logic)
    priv_keys=()
    if [ -d "$SSH_DIR" ]; then
        # Look for private keys (files without .pub extension that have corresponding .pub files)
        while IFS= read -r -d '' file; do
            # Get the base name without .pub
            base_name="${file%.pub}"
            # Check if the private key exists
            if [ -f "$base_name" ]; then
                priv_keys+=("$base_name")
            fi
        done < <(find "$SSH_DIR" -maxdepth 1 -name "*.pub" -type f -print0 2>/dev/null)
        
        # Also look for .pem files (common for AWS/cloud keys)
        while IFS= read -r -d '' file; do
            priv_keys+=("$file")
        done < <(find "$SSH_DIR" -maxdepth 1 -name "*.pem" -type f -print0 2>/dev/null)
    fi
    
    # If we found any private keys, let user choose
    if [ ${#priv_keys[@]} -gt 0 ]; then
        echo "  Found ${#priv_keys[@]} SSH private key(s):"
        for i in "${!priv_keys[@]}"; do
            echo "    $((i+1)). $(basename "${priv_keys[$i]}")"
        done
        echo ""
        
        if [ ${#priv_keys[@]} -eq 1 ]; then
            # Only one key, use it automatically
            SSH_KEY="-i ${priv_keys[0]}"
            echo "  Using private key: ${priv_keys[0]}"
        else
            # Multiple keys, ask user to choose
            read -p "Select a key to use (1-${#priv_keys[@]}): " key_choice
            
            if [ "$key_choice" -gt 0 ] && [ "$key_choice" -le ${#priv_keys[@]} ]; then
                selected_key="${priv_keys[$((key_choice-1))]}"
                SSH_KEY="-i $selected_key"
                echo "  Using private key: $selected_key"
            else
                echo "ERROR: Invalid selection"
                exit 1
            fi
        fi
    else
        # Fallback to common key names
        for key_file in "$SSH_DIR/id_rsa" "$SSH_DIR/id_ed25519" "$SSH_DIR/id_ecdsa" "$SSH_DIR/devdocker_rsa"; do
            if [ -f "$key_file" ]; then
                SSH_KEY="-i $key_file"
                echo "  Using private key: $key_file"
                break
            fi
        done
    fi
    
    if [ -z "$SSH_KEY" ]; then
        echo "WARNING: No matching private key found in $SSH_DIR"
        echo "Make sure you have the private key corresponding to the public key in ./ssh-keys/authorized_keys"
        exit 1
    fi
else
    echo "WARNING: No SSH keys found in ./ssh-keys/authorized_keys"
    echo "Run: ./scripts/setup-ssh-keys.sh"
    exit 1
fi

echo ""
echo "Testing SSH connection to localhost:${SSH_PORT}..."
echo ""

# Try to connect with retries (SSH server might need a moment to start)
for i in $(seq 1 $MAX_RETRIES); do
    if ssh $SSH_KEY -o StrictHostKeyChecking=no -o ConnectTimeout=5 -p "$SSH_PORT" root@localhost "echo '✓ SSH connection successful!'" 2>/dev/null; then
        echo ""
        echo "=== SSH Connection Test: PASSED ==="
        echo ""
        echo "You can now connect to the container:"
        echo "  ssh $SSH_KEY -p $SSH_PORT root@localhost"
        echo ""
        echo "Workspace directories:"
        ssh $SSH_KEY -o StrictHostKeyChecking=no -p "$SSH_PORT" root@localhost "ls -la /workspace/" 2>/dev/null
        exit 0
    else
        if [ $i -lt $MAX_RETRIES ]; then
            echo "Attempt $i/$MAX_RETRIES failed, retrying in ${RETRY_DELAY}s..."
            sleep $RETRY_DELAY
        fi
    fi
done

echo ""
echo "=== SSH Connection Test: FAILED ==="
echo ""
echo "Troubleshooting steps:"
echo "  1. Verify SSH keys are configured: ls -la ./ssh-keys/"
echo "  2. Check container logs: docker-compose logs devdocker"
echo "  3. Verify SSH server is running: docker-compose exec devdocker ps aux | grep sshd"
echo "  4. Check port mapping: docker-compose ps"
echo ""
exit 1
