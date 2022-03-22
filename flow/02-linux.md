# Linux networking

In this section, we'll be looking at how networking is configured on a linux machine. We'll be using a utility called `ip` from the `iproute2` package. You can use your distro's package manager to search for `iproute2` package and install it.

We'll also be using `ping` to test connectivity.

Linux organized the network into some primitives, links, addresses, neighbors and routes. Links are the network pathways connected to the different network interfaces, physical or virtual. Neighbors are simply the network neighbors that the current host has connected to in the past. Routes are the paths through links and through border devices to get to the other nodes in a larger network.

## Links

You can see the network links configured within the host and the IP addresses assigned to each link using `ip link show`. Sample output follows, some of the IP addresses and MAC addresses are omitted.

```
$ ip link show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: enp0s31f6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether <ipv6_address> brd ff:ff:ff:ff:ff:ff
```

There are two links detailed in the sample output, one is a loopback link (that comes back to the host) and one is an ethernet link with the IP address specified by `<ipv6_address>`.

As part of the listing, we also see certain statuses between angle brackets, the ones that we most care about are

- `LOOPBACK` - this link serves as loopback
- `UP` - this link is active
- `LOWER_UP` - underlying physical media is connected
- `BROADCAST` - link contains a valid broadcast address
- `MULTICAST` - link supports multicast
- `NO_CARRIER` - underlying physical media is disconnected

There are other properties of each link listed, like the broadcast address denoted by the `brd` address and the queue length (in packets) that the link supports. In the case of the enp0s31f6 link, the first 1000 packets will be queued, the 1001st packet will be dropped.

## Neighbors

You can use the `ip n` (or `ip neigh` or `ip neighbor`) command to see the network neighbors that the host has recently interacted with. A network neighbor is a node that is connected to the same network as the host. Commonly, these would be devices on the same wireless network or devices connected via an ethernet cable to the same router.

Running the command outputs the following

```
192.168.0.10 dev enp0s31f6 lladdr <device_mac_address> STALE
192.168.0.10 dev wlp4s0 lladdr <device_mac_address> STALE
192.168.0.239 dev enp0s31f6 lladdr <device_mac_address> REACHABLE
192.168.0.1 dev enp0s31f6 lladdr <device_mac_address> REACHABLE
172.17.0.2 dev docker0 lladdr <device_mac_address> DELAY
```

Breaking this output down, we can see that the physical address (the MAC address) of the neighbor device is listed as well as the IP address that the device has been assigned by the network.

Additionally, for each neighbor, you can see the link that is used to get to it and the status of that neighbor. There are several statuses that can be seen in the output, we'll go through what they mean below

- `REACHABLE` - the neighbor is connected and verified
- `STALE` - the neighbor has not recently been verified, no action to take until sending traffic to it
- `DELAY` - a verify packet has been sent to the neighbor in the last 5 seconds but no response has been received
- `FAILED` - the neighbor has been sent verify packets but no response has been received after maximum retries

## Routes

You can use the `ip route` command to see registered routes to nodes on other networks that the host knows about.
