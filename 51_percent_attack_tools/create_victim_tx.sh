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
