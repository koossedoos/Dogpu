#!/bin/bash
echo "📊 Node Status Check:"
echo "===================="

echo "Honest Node Block Count:"
./dogpu-cli -datadir=honest_node getblockcount 2>/dev/null || echo "❌ Not responding"

echo "Victim Node Block Count:"  
./dogpu-cli -datadir=victim_node getblockcount 2>/dev/null || echo "❌ Not responding"

echo "Attack Node Block Count:"
./dogpu-cli -datadir=attack_node getblockcount 2>/dev/null || echo "❌ Not responding"

echo ""
echo "Network Info:"
./dogpu-cli -datadir=honest_node getnetworkinfo 2>/dev/null | grep -E "(connections|version)" || echo "❌ Network info unavailable"
