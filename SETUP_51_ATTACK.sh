#!/bin/bash

# 51% Attack Setup Script for DogeGPU Blockchain
# This script will compile DogeGPU and set up the attack environment

echo "🎯 DogeGPU 51% Attack Setup"
echo "============================"
echo "📊 Target: Block 1,861,257 | 970 MH/s network hashrate"
echo "⚡ Required: >485 MH/s for 51% attack"
echo ""

# Check if running on correct system
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "❌ This script requires Linux. Please run on Ubuntu/Debian."
    exit 1
fi

echo "🔧 Installing dependencies..."
sudo apt update
sudo apt install -y git build-essential libtool autotools-dev automake pkg-config \
    libssl-dev libevent-dev bsdmainutils python3 libboost-all-dev libdb++-dev \
    libminiupnpc-dev

echo "📥 Cloning DogeGPU source code..."
if [ ! -d "DogeGPU-master" ]; then
    wget https://github.com/Masterscooper/Dogegpu/archive/refs/heads/master.zip
    unzip master.zip
    rm master.zip
fi

cd DogeGPU-master

echo "🔨 Compiling DogeGPU (this may take 10-15 minutes)..."

# Apply compatibility fixes
sed -i '31a#include <stdexcept>' src/support/lockedpool.cpp
sed -i '16a#include <cstdint>' src/bench/bench.h

# Configure and compile
./autogen.sh
./configure --disable-wallet --disable-tests --disable-gui --disable-bench
make -j$(nproc)

if [ $? -eq 0 ]; then
    echo "✅ DogeGPU compiled successfully!"
else
    echo "❌ Compilation failed. Check error messages above."
    exit 1
fi

# Set up attack environment
cd ..
mkdir -p attack_environment/{honest_node,victim_node,attack_node}

# Copy binaries
cp DogeGPU-master/src/dogpud attack_environment/
cp DogeGPU-master/src/dogpu-cli attack_environment/
chmod +x attack_environment/dogpu*

# Copy attack scripts
cp -r 51_percent_attack_setup/* attack_environment/

echo ""
echo "🎉 SETUP COMPLETE!"
echo "=================="
echo "✅ DogeGPU binaries compiled"
echo "✅ Attack environment ready"
echo "✅ All scripts prepared"
echo ""
echo "📁 Attack directory: ./attack_environment/"
echo ""
echo "🚀 Next Steps:"
echo "1. cd attack_environment"
echo "2. ./execute_51_attack.sh"
echo "3. Point your rented hashpower to port 8335"
echo "4. Execute the double-spend attack!"
echo ""
echo "💡 Your rented hashpower (>485 MH/s) should target: localhost:8335"
echo "🔥 Ready to demonstrate 51% attack on your private blockchain!"