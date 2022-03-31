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

## Tracing a name to an IP

In this section we'll learn about how our computers trace through multiple servers and resolve an IP address from a domain name. This is something that our computers and our networks are already configured to do but the mechanics of it are interesting to understand. We'll start with one of the root servers and try to figure out what IP address maps to www.google.com.

```
$ dig @199.7.91.13 www.google.com

; <<>> DiG 9.16.15-Ubuntu <<>> @199.7.91.13 www.google.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 18228
;; flags: qr rd; QUERY: 1, ANSWER: 0, AUTHORITY: 13, ADDITIONAL: 27
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1450
;; QUESTION SECTION:
;www.google.com.                        IN      A

;; AUTHORITY SECTION:
com.                    172800  IN      NS      a.gtld-servers.net.
com.                    172800  IN      NS      b.gtld-servers.net.
com.                    172800  IN      NS      c.gtld-servers.net.
com.                    172800  IN      NS      d.gtld-servers.net.
com.                    172800  IN      NS      e.gtld-servers.net.
com.                    172800  IN      NS      f.gtld-servers.net.
com.                    172800  IN      NS      g.gtld-servers.net.
com.                    172800  IN      NS      h.gtld-servers.net.
com.                    172800  IN      NS      i.gtld-servers.net.
com.                    172800  IN      NS      j.gtld-servers.net.
com.                    172800  IN      NS      k.gtld-servers.net.
com.                    172800  IN      NS      l.gtld-servers.net.
com.                    172800  IN      NS      m.gtld-servers.net.

;; ADDITIONAL SECTION:
a.gtld-servers.net.     172800  IN      A       192.5.6.30
b.gtld-servers.net.     172800  IN      A       192.33.14.30
c.gtld-servers.net.     172800  IN      A       192.26.92.30
d.gtld-servers.net.     172800  IN      A       192.31.80.30
e.gtld-servers.net.     172800  IN      A       192.12.94.30
f.gtld-servers.net.     172800  IN      A       192.35.51.30
g.gtld-servers.net.     172800  IN      A       192.42.93.30
h.gtld-servers.net.     172800  IN      A       192.54.112.30
i.gtld-servers.net.     172800  IN      A       192.43.172.30
j.gtld-servers.net.     172800  IN      A       192.48.79.30
k.gtld-servers.net.     172800  IN      A       192.52.178.30
l.gtld-servers.net.     172800  IN      A       192.41.162.30
m.gtld-servers.net.     172800  IN      A       192.55.83.30
a.gtld-servers.net.     172800  IN      AAAA    2001:503:a83e::2:30
b.gtld-servers.net.     172800  IN      AAAA    2001:503:231d::2:30
c.gtld-servers.net.     172800  IN      AAAA    2001:503:83eb::30
d.gtld-servers.net.     172800  IN      AAAA    2001:500:856e::30
e.gtld-servers.net.     172800  IN      AAAA    2001:502:1ca1::30
f.gtld-servers.net.     172800  IN      AAAA    2001:503:d414::30
g.gtld-servers.net.     172800  IN      AAAA    2001:503:eea3::30
h.gtld-servers.net.     172800  IN      AAAA    2001:502:8cc::30
i.gtld-servers.net.     172800  IN      AAAA    2001:503:39c1::30
j.gtld-servers.net.     172800  IN      AAAA    2001:502:7094::30
k.gtld-servers.net.     172800  IN      AAAA    2001:503:d2d::30
l.gtld-servers.net.     172800  IN      AAAA    2001:500:d937::30
m.gtld-servers.net.     172800  IN      AAAA    2001:501:b1f9::30

;; Query time: 0 msec
;; SERVER: 199.7.91.13#53(199.7.91.13)
;; WHEN: Mon Mar 28 18:13:33 PDT 2022
;; MSG SIZE  rcvd: 839
```

Here, we started with `d.root-servers.net` as our starting point and asked it what it knows about www.google.com using the command `dig @199.7.91.13 www.google.com`. This gave us the above output. The first line to pay attention to is `QUERY: 1, ANSWER: 0, AUTHORITY: 13, ADDITIONAL: 27`. This tells us that we sent 1 query, we got 0 answers, we found 13 authorities, and there are 27 additional items that we should know about.

If we look in the authority section, we see entries that look like the following,

```
com.                    172800  IN      NS      a.gtld-servers.net.
```

This says, the server at `a.gtld-servers.net` is an authority (NS) for `com.` and that record will stay alive for 2 days. In the additional section, we see corresponding entries for each authority in the authority section that look like the following,

```
a.gtld-servers.net.     172800  IN      A       192.5.6.30
```

This says, the server that has the name `a.gtld-servers.net` is located at 192.5.6.30. This record will stay alive for 2 days as well and is an A record. Now we will ask the authority server that we've just been told about for what it knows about www.google.com using `dig @192.5.6.30 www.google.com`. That output looks like the following,

```
$ dig @192.5.6.30 www.google.com

; <<>> DiG 9.16.15-Ubuntu <<>> @192.5.6.30 www.google.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 43384
;; flags: qr rd; QUERY: 1, ANSWER: 0, AUTHORITY: 4, ADDITIONAL: 9
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.google.com.                        IN      A

;; AUTHORITY SECTION:
google.com.             172800  IN      NS      ns2.google.com.
google.com.             172800  IN      NS      ns1.google.com.
google.com.             172800  IN      NS      ns3.google.com.
google.com.             172800  IN      NS      ns4.google.com.

;; ADDITIONAL SECTION:
ns2.google.com.         172800  IN      AAAA    2001:4860:4802:34::a
ns2.google.com.         172800  IN      A       216.239.34.10
ns1.google.com.         172800  IN      AAAA    2001:4860:4802:32::a
ns1.google.com.         172800  IN      A       216.239.32.10
ns3.google.com.         172800  IN      AAAA    2001:4860:4802:36::a
ns3.google.com.         172800  IN      A       216.239.36.10
ns4.google.com.         172800  IN      AAAA    2001:4860:4802:38::a
ns4.google.com.         172800  IN      A       216.239.38.10

;; Query time: 0 msec
;; SERVER: 192.5.6.30#53(192.5.6.30)
;; WHEN: Mon Mar 28 18:24:31 PDT 2022
;; MSG SIZE  rcvd: 291
```

We see that we still get 0 answers, but we have found 4 new authorities, this time for `google.com` and their corresponding IP addresses. Maybe if we talk to one of those, we'll find out what www.google.com maps to. Running a similar command with a different target this time, we get

```
$ dig @216.239.34.10 www.google.com

; <<>> DiG 9.16.15-Ubuntu <<>> @216.239.34.10 www.google.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 41526
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;www.google.com.                        IN      A

;; ANSWER SECTION:
www.google.com.         300     IN      A       142.251.33.100

;; Query time: 11 msec
;; SERVER: 216.239.34.10#53(216.239.34.10)
;; WHEN: Mon Mar 28 18:26:56 PDT 2022
;; MSG SIZE  rcvd: 59
```

Aha! This one has an answer. And it says, 1 answer, which tells us that www.google.com maps to 142.251.33.100. Something to note is that record is only alive for 300 seconds, or 5 minutes. This means that likely, by the time you read this, that information would have already changed.

Computers don't usually do all of this digging every time you go to www.google.com though. They just ask the nearest cache that knows about how to reach www.google.com. If we don't specify a target for the dig command, we'll get a similar, if not the same, output.

```
$ dig www.google.com

; <<>> DiG 9.16.15-Ubuntu <<>> www.google.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 35168
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;www.google.com.                        IN      A

;; ANSWER SECTION:
www.google.com.         225     IN      A       142.250.217.100

;; Query time: 3 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Mon Mar 28 18:30:44 PDT 2022
;; MSG SIZE  rcvd: 59
```

This followup command was run a bit later after the last command in our dig chain. So the record has already changed to point to a different location and at this cache server, this record is only alive for 3 minutes and 45 seconds.

## Tracing your path to an IP

Now that we have an IP address for a DNS name, we can actually trace through the network to find the path that our packets will use to talk to the IP address. This will be done using a utility called `traceroute`. We'll start with a DNS resolution command again just because that record could have changed. Running `dig www.google.com` provides us with the following information, that server resides at 172.217.5.4. So then running `traceroute 172.217.5.4` provides us with the following output

```
$ traceroute 172.217.5.4
traceroute to 172.217.5.4 (172.217.5.4), 64 hops max, 52 byte packets
 1  gateway (192.168.1.1)  2.364 ms  2.006 ms  1.945 ms
 2  142-254-149-013.inf.spectrum.com (142.254.149.13)  15.150 ms  10.268 ms  10.951 ms
 3  lag-63.wevlohoh02h.netops.charter.com (24.95.81.41)  15.019 ms  13.758 ms  20.903 ms
 4  lag-88.clmcohib01r.netops.charter.com (65.29.17.66)  15.768 ms  14.965 ms  23.826 ms
 5  lag-27.clevohek01r.netops.charter.com (65.29.1.38)  25.520 ms  25.451 ms  24.989 ms
 6  lag-17.vinnva0510w-bcr00.netops.charter.com (66.109.6.70)  31.075 ms
    lag-27.vinnva0510w-bcr00.netops.charter.com (66.109.6.66)  27.740 ms
    lag-415.vinnva0510w-bcr00.netops.charter.com (66.109.6.12)  39.520 ms
 7  lag-11.asbnva1611w-bcr00.netops.charter.com (66.109.6.30)  39.990 ms  30.785 ms  43.387 ms
 8  72.14.214.10 (72.14.214.10)  29.871 ms
    72.14.220.190 (72.14.220.190)  28.050 ms  50.656 ms
 9  * * *
10  108.170.246.33 (108.170.246.33)  30.020 ms
    108.170.240.97 (108.170.240.97)  33.871 ms
    108.170.246.33 (108.170.246.33)  28.978 ms
11  108.170.240.112 (108.170.240.112)  29.858 ms
    108.170.246.3 (108.170.246.3)  27.856 ms
    108.170.246.34 (108.170.246.34)  27.126 ms
12  209.85.241.125 (209.85.241.125)  40.465 ms *
    216.239.50.97 (216.239.50.97)  36.940 ms
13  209.85.250.8 (209.85.250.8)  33.221 ms  52.779 ms *
14  209.85.241.125 (209.85.241.125)  36.199 ms  34.040 ms
    142.251.234.41 (142.251.234.41)  32.865 ms
15  108.170.243.193 (108.170.243.193)  33.957 ms
    108.170.243.174 (108.170.243.174)  34.687 ms
    108.170.243.193 (108.170.243.193)  34.994 ms
16  209.85.255.145 (209.85.255.145)  36.494 ms  35.745 ms
    209.85.255.173 (209.85.255.173)  36.470 ms
17  ord38s19-in-f4.1e100.net (172.217.5.4)  33.727 ms  39.614 ms  34.023 ms
```

Let us study this output. The first thing to notice is this header,

```
traceroute to 172.217.5.4 (172.217.5.4), 64 hops max, 52 byte packets
```

This says, we're going to use a packet size of 52 bytes, and we're going to trace the path for a maximum of 64 hops. The next line says, we're going to trace the path to the IP address that we provided.

The next thing to notice is this pattern,

```
# dns_name (ip_address) millis millis millis
```

This is the default traceroute output, where the first column is the hop number, the second one is the DNS name and an IP address of the hop, and the last three columns are the time it took the server at that hop to respond. Traceroute samples three data points per hop and it displays all three numbers.

If for example, a device in the middle of the route is not configured to accept ICMP packets over UDP, that is likely to show up as a `*` in the middle of the output. If the traceroute stops with `*`s, then we know that something is broken in the network. Generally, if you are tracing through the internet, you shouldn't be running into broken hops unless we're in a situation where Facebook locked their network out from the internet.

The next thing to note is,

```
10  108.170.246.33 (108.170.246.33)  30.020 ms
    108.170.240.97 (108.170.240.97)  33.871 ms
    108.170.246.33 (108.170.246.33)  28.978 ms
```

It was found that there were three different paths we could take through this hop and since we are using three tries per hop, each server was tried once.

Traceroute provides different configuration options to change these defaults. We can use,

- the `-m` option to change the maximum number of hops
- the `-M` option to change the minimum number of hops
- the `-i` option to change the interface we are using for traceroute
- the `-w` option to change the number of seconds to wait for a response
- the `-q` option to change the number of probes to send per hop
- the `-v` option for verbose output
