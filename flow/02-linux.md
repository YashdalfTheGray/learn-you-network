# Linux networking

In this section, we'll be looking at how networking is configured on a linux machine. We'll be using a utility called `ip` from the `iproute2` package. You can use your distro's package manager to search for `iproute2` package and install it.

We'll also be using `ping` to test connectivity.

Linux organized the network into some primitives, links, addresses, neighbors and routes. Links are the network pathways connected to the different network interfaces, physical or virtual. Neighbors are simply the network neighbors that the current host has connected to in the past. Routes are the paths through links and through border devices to get to the other nodes in a larger network. 

## Links

You can see the network links configured within the host and the IP addresses assigned to each link using `ip link show`. 

## Neighbors

You can use the `ip n` command to see the network neighbors that the host has recently interacted with. 

## Routes

You can use the `ip route` command to see registered routes to nodes on other networks that the host knows about. 