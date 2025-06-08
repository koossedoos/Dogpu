#!/bin/bash

echo "🎯 DogeGPU 51% Attack Setup for Your Server"
echo "============================================"
echo "Educational purposes only!"
echo ""

# Check if we're in the right directory
if [ ! -f "../DogeGPU-master/src/dogpud.cpp" ]; then
    echo "❌ Error: Please run this from the 51_percent_attack_tools directory"
    echo "Expected structure: Dogpu/51_percent_attack_tools/"
    exit 1
fi

echo "📦 Installing dependencies..."
sudo apt update
sudo apt install -y build-essential libtool autotools-dev automake pkg-config \
    libssl-dev libevent-dev bsdmainutils python3 python3-pip \
    libboost-all-dev libminiupnpc-dev libdb++-dev

echo "🐍 Installing Python dependencies..."
pip3 install requests

echo "🔨 Compiling DogeGPU binaries..."
cd ../DogeGPU-master

# Clean and compile
make clean 2>/dev/null || true
./autogen.sh
./configure --disable-wallet --disable-tests --disable-gui --disable-bench
make -j$(nproc)

if [ $? -eq 0 ]; then
    echo "✅ Compilation successful!"
    
    # Copy binaries to attack tools directory
    cp src/dogpud ../51_percent_attack_tools/
    cp src/dogpu-cli ../51_percent_attack_tools/
    chmod +x ../51_percent_attack_tools/dogpud ../51_percent_attack_tools/dogpu-cli
    
    echo "✅ Binaries copied to attack tools directory"
else
    echo "❌ Compilation failed!"
    echo "Please check the error messages above and install missing dependencies"
    exit 1
fi

cd ../51_percent_attack_tools

echo "🎯 Testing binaries..."
./dogpud --version
./dogpu-cli --version

echo ""
echo "🚀 SETUP COMPLETE!"
echo "=================="
echo ""
echo "Your 51% attack environment is ready!"
echo ""
echo "Next steps:"
echo "1. ./START_ATTACK.sh    - See all available commands"
echo "2. Start your attack nodes in separate terminals"
echo "3. Connect your rented hashpower to port 8335"
echo "4. Execute attacks!"
echo ""
echo "📊 Your Network Status:"
echo "- Block Height: 1861257"
echo "- Network Hashrate: 970 MH/s"
echo "- Algorithm: X16R"
echo ""
echo "🎯 Ready to test your blockchain's security!"