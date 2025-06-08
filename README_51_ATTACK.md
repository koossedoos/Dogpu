# DogeGPU 51% Attack Tools

**Educational purposes only - for private test chains**

## 🎯 Complete 51% Attack Suite

This repository contains a complete suite of tools for testing 51% attacks against your DogeGPU blockchain. Since you've rented hashpower and want to test the security of your private test chain, these tools will help you execute various attack scenarios.

## 📁 Directory Structure

```
51_percent_attack_tools/
├── dogpud                      # DogeGPU daemon (compiled)
├── dogpu-cli                   # DogeGPU CLI tool (compiled)
├── START_ATTACK.sh             # Main entry point
├── ATTACK_GUIDE.md             # Complete attack documentation
├── advanced_attack_tools.py    # Python attack suite
├── setup_attack.sh             # Initial setup script
├── start_honest.sh             # Start honest network node
├── start_victim.sh             # Start victim node
├── start_attack.sh             # Start attack node
├── double_spend_attack.sh      # Simple double spend attack
└── honest_node/                # Honest node data directory
└── attack_node/                # Attack node data directory
└── victim_node/                # Victim node data directory
```

## 🚀 Quick Setup on Your Server

### Step 1: Clone and Setup
```bash
git clone https://github.com/koossedoos/Dogpu.git
cd Dogpu/51_percent_attack_tools
chmod +x *.sh *.py
```

### Step 2: Setup and Compile
```bash
# Run the automated setup script
./SETUP_ON_SERVER.sh

# This will:
# - Install all dependencies
# - Compile DogeGPU binaries
# - Set up the attack environment
# - Test everything works
```

### Step 3: Start Attack Environment
```bash
# Terminal 1 - Honest Network
./start_honest.sh

# Terminal 2 - Victim Node  
./start_victim.sh

# Terminal 3 - Attack Node
./start_attack.sh
```

### Step 4: Connect Your Rented Hashpower
Point your miners to:
- **Host**: Your server IP
- **Port**: 8335
- **Algorithm**: X16R

### Step 5: Execute Attacks
```bash
# Simple double spend
./double_spend_attack.sh

# Advanced attack suite
python3 advanced_attack_tools.py
```

## 💀 Available Attack Types

1. **Double Spend Attack** - Reverse transactions after confirmation
2. **Selfish Mining** - Mine privately then release strategically  
3. **Eclipse Attack** - Isolate victim nodes from honest network
4. **Finney Attack** - Pre-mine blocks with conflicting transactions
5. **Race Attack** - Broadcast conflicting transactions simultaneously

## 📊 Your Network Status
- **Current Block**: 1861257
- **Network Hashrate**: 970 MH/s
- **Your Hashpower**: Ready to connect
- **Algorithm**: X16R (DogeGPU)

## 🛡️ Security Analysis

This will help you identify vulnerabilities in your blockchain:
- Test resistance to 51% attacks
- Analyze double-spending feasibility
- Evaluate network consensus mechanisms
- Identify defense weaknesses

## ⚠️ Important Notes

- **Educational purposes only**
- **Use only on your private test chain**
- **Real attacks on live networks are illegal**
- **This helps improve blockchain security**

## 📞 Support

If you need help with the attack setup:
1. Check the `ATTACK_GUIDE.md` for detailed instructions
2. Run `./START_ATTACK.sh` for quick commands
3. Use `python3 advanced_attack_tools.py` for interactive attacks

**Ready to test your blockchain's security! 🎯**