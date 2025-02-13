# **Linux Network Namespace Simulation Documentation**

## **1. Introduction**
Network namespaces in Linux allow for isolated network environments within a single host. This guide walks through setting up a simple network simulation using Linux network namespaces and bridges. By the end, we’ll have two separate networks connected through a router namespace.

### **Objective**
We’re going to create:
- **Network Bridges**
  - `br0` (Bridge 0)
  - `br1` (Bridge 1)
- **Network Namespaces**
  - `ns1` (Connected to `br0`)
  - `ns2` (Connected to `br1`)
  - `router-ns` (Acts as a router between `br0` and `br1`)

## **2. Network Topology**
```
   ns1 --- veth1 --- br0 --- veth-r0 --- router-ns --- veth-r1 --- br1 --- veth2 --- ns2
```
- **ns1** connects to `br0`.
- **ns2** connects to `br1`.
- **router-ns** acts as the bridge between them.

## **3. Step-by-Step Setup**

### **Step 1: Create Network Namespaces**
Network namespaces create isolated network environments.
```bash
ip netns add ns1
ip netns add ns2
ip netns add router-ns
```
Verify creation using:
```bash
ip netns list
```

### **Step 2: Create Network Bridges**
Bridges work as virtual switches, connecting different network namespaces.
```bash
ip link add br0 type bridge
ip link add br1 type bridge
ip link set br0 up
ip link set br1 up
```
Check bridge creation:
```bash
ip link show type bridge
```

### **Step 3: Create Virtual Ethernet (veth) Pairs**
Virtual Ethernet (veth) pairs provide links between namespaces and bridges.
```bash
ip link add veth1 type veth peer name veth1-br
ip link add veth2 type veth peer name veth2-br
ip link add veth-r0 type veth peer name veth-r0-br
ip link add veth-r1 type veth peer name veth-r1-br
```
Verify with:
```bash
ip link show | grep veth
```

### **Step 4: Assign veth Interfaces to Namespaces**
```bash
ip link set veth1 netns ns1
ip link set veth2 netns ns2
ip link set veth-r0 netns router-ns
ip link set veth-r1 netns router-ns
```
Confirm using:
```bash
ip netns exec ns1 ip link show
```

### **Step 5: Connect Interfaces to Bridges**
```bash
ip link set veth1-br master br0
ip link set veth2-br master br1
ip link set veth-r0-br master br0
ip link set veth-r1-br master br1
```

### **Step 6: Assign IP Addresses**
```bash
ip netns exec ns1 ip addr add 192.168.1.2/24 dev veth1
ip netns exec ns2 ip addr add 192.168.2.2/24 dev veth2
ip netns exec router-ns ip addr add 192.168.1.1/24 dev veth-r0
ip netns exec router-ns ip addr add 192.168.2.1/24 dev veth-r1
```
Verify with:
```bash
ip netns exec ns1 ip addr show
```


### **Step 7: Configure Routing**
```bash
ip netns exec ns1 ip route add default via 192.168.1.1
ip netns exec ns2 ip route add default via 192.168.2.1
ip netns exec router-ns ip route add 192.168.1.0/24 dev veth-r0
ip netns exec router-ns ip route add 192.168.2.0/24 dev veth-r1
```

### **Step 8: Configure iptables for Packet Forwarding**
```bash
ip netns exec router-ns iptables --append FORWARD --in-interface br0 --jump ACCEPT
ip netns exec router-ns iptables --append FORWARD --out-interface br0 --jump ACCEPT
ip netns exec router-ns iptables --append FORWARD --in-interface br1 --jump ACCEPT
ip netns exec router-ns iptables --append FORWARD --out-interface br1 --jump ACCEPT
```

### **Step 9: Running the Setup Script**
Save these commands in `setup_network.sh`, make it executable, and run:
```bash
chmod +x setup_network.sh
./setup_network.sh
```

### **Step 10: Cleanup Script**
For easy teardown, create `cleanup_network.sh`:
```bash
#!/bin/bash
ip netns del ns1
ip netns del ns2
ip netns del router-ns
ip link del br0
ip link del br1
```
Make it executable and run:
```bash
chmod +x cleanup_network.sh
./cleanup_network.sh
```

## **4. Testing Connectivity**
### **Ping Tests**
1. **Check ns1 to Router:**
   ```bash
   ip netns exec ns1 ping -c 3 192.168.1.1
   ```
2. **Check ns2 to Router:**
   ```bash
   ip netns exec ns2 ping -c 3 192.168.2.1
   ```
3. **Check Full Connectivity (ns1 to ns2 via router):**
   ```bash
   ip netns exec ns1 ping -c 3 192.168.2.2
   ```


