#!/bin/bash

set -e  # Exit immediately on error

echo "Creating network namespaces..."
ip netns add ns1
ip netns add ns2
ip netns add router-ns

echo "Creating network bridges..."
ip link add br0 type bridge
ip link add br1 type bridge
ip link set br0 up
ip link set br1 up

echo "Creating virtual Ethernet (veth) pairs..."
ip link add veth1 type veth peer name veth1-br
ip link add veth2 type veth peer name veth2-br
ip link add veth-r0 type veth peer name veth-r0-br
ip link add veth-r1 type veth peer name veth-r1-br

echo "Connecting veth interfaces to namespaces..."
ip link set veth1 netns ns1
ip link set veth2 netns ns2
ip link set veth-r0 netns router-ns
ip link set veth-r1 netns router-ns

echo "Attaching interfaces to bridges..."
ip link set veth1-br master br0
ip link set veth2-br master br1
ip link set veth-r0-br master br0
ip link set veth-r1-br master br1

echo "Bringing up bridge-side veth interfaces..."
ip link set veth1-br up
ip link set veth2-br up
ip link set veth-r0-br up
ip link set veth-r1-br up

echo "Setting up IP addresses..."
ip netns exec ns1 ip addr add 192.168.1.2/24 dev veth1
ip netns exec ns2 ip addr add 192.168.2.2/24 dev veth2
ip netns exec router-ns ip addr add 192.168.1.1/24 dev veth-r0
ip netns exec router-ns ip addr add 192.168.2.1/24 dev veth-r1

echo "Bringing up veth interfaces..."
ip netns exec ns1 ip link set veth1 up
ip netns exec ns2 ip link set veth2 up
ip netns exec router-ns ip link set veth-r0 up
ip netns exec router-ns ip link set veth-r1 up


echo "Setting up routing in namespaces..."
ip netns exec ns1 ip route add default via 192.168.1.1
ip netns exec ns2 ip route add default via 192.168.2.1

echo "Setting up forwarding rules in router-ns..."
ip netns exec router-ns ip route add 192.168.1.0/24 dev veth-r0
ip netns exec router-ns ip route add 192.168.2.0/24 dev veth-r1

echo "Configuring iptables rules for forwarding..."
ip netns exec router-ns iptables --append FORWARD --in-interface br0 --jump ACCEPT
ip netns exec router-ns iptables --append FORWARD --out-interface br0 --jump ACCEPT
ip netns exec router-ns iptables --append FORWARD --in-interface br1 --jump ACCEPT
ip netns exec router-ns iptables --append FORWARD --out-interface br1 --jump ACCEPT

echo "Testing connectivity..."
ip netns exec ns1 ping -c 3 192.168.1.1   # Router reachable?
ip netns exec ns2 ping -c 3 192.168.2.1   # Router reachable?
ip netns exec ns1 ping -c 3 192.168.2.2   # Full connectivity?

echo "Network setup completed successfully!"
