# Linux networking

In this section, we'll be looking at how networking is configured on a linux machine. We'll be using a utility called `ip` from the `iproute2` package. You can use your distro's package manager to search for `iproute2` package and install it.

We'll also be using `ping` to test connectivity and `dig` and `traceroute` to find our way around the internet.

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

You can use the `ip n show` (or `ip neigh show` or `ip neighbor show`) command to see the network neighbors that the host has recently interacted with. A network neighbor is a node that is connected to the same network as the host. Commonly, these would be devices on the same wireless network or devices connected via an ethernet cable to the same router.

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

You can use the `ip route show` command to see registered routes to nodes on other networks that the host knows about. The output of the command looks like this for a particular host

```
default via 192.168.0.1 dev enp0s31f6 proto dhcp metric 100
default via 192.168.0.1 dev wlp4s0 proto dhcp metric 600
169.254.0.0/16 dev enp0s31f6 scope link metric 1000
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1
192.168.0.0/24 dev enp0s31f6 proto kernel scope link src 192.168.0.50 metric 100
192.168.0.0/24 dev wlp4s0 proto kernel scope link src 192.168.0.164 metric 600
```

We can learn a lot about a node's network neighborhood from the routes that are displayed int his output. Starting from the bottom,

- There is a known route to the subnet 192.168.0.0/24 that is connected to the enp0s31f6 interface. The IP address assigned to that particular link is 192.168.0.50.
- There is another known route to the subnet 192.168.0.0/24 that is connected to the wlp4s0 interface. The IP address assigned to that particular link is 192.168.0.164.
- We can access the docker network specified by the subnet 172.17.0.0/16 via the docker0 interface. The IP address assigned to that link is 172.17.0.1.
- We can access the self-assigned IP address space specified by 169.254.0.0/16 (if computers are connected to each other but not a routing or DHCP device) via the enp0s31f6 interface.
- There are two default routes via 192.168.0.1 for the two links enp0s31f6 and wlp4s0.

The next question is, "well what do these things mean?" To explain this, we're going to walk through some examples.

The first example will be to ping the node 192.168.0.40 assuming that that IP address is assigned to a device and it will respond to pings. In this example, when the host pings the node, it will look up the IP address in the route table, realize that it can get through to the address using two different interfaces. It will then pick the route with the lowest metric and send the ping to the node.

The second example works similar to the first one, if we wanted to access a node on docker network or the self-assigned IP subnet, we would be using different links but the same process for finding the route. Those addresses will end up on the same subnet that the route specifies and we'll use that route to access the node on the other end.

The third example is to access a node with an address that is not listed as a route in our route table. This will use the default route through the interface with the lowest metric. It will also use the gateway for that route, in this case denoted by 192.168.0.1. For example, if we were to access something like google.com, we would use the default route because we don't have a direct route stored to Google's servers on our local route table.

The gateway with the address 192.168.0.1 also has a route table and will try to look up the address space for google.com in its route table. If it doesn't find a route, it will also use its default route to pass the traffic along.

Eventually, we'll find a gateway with the address space for google.com and that gateway will route our traffic to the right host. Note, that this all happens after DNS resolution so that we already know the IP address we want to get to.

## What's in a name?
