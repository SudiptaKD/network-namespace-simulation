#!/bin/bash

echo "Cleaning up network namespaces and bridges..."

# Delete namespaces
ip netns del ns1
ip netns del ns2
ip netns del router-ns

# Delete bridges
ip link del br0
ip link del br1

# Delete veth pairs
ip link del veth1-br
ip link del veth2-br
ip link del veth-r0-br
ip link del veth-r1-br

echo "Cleanup complete!"
