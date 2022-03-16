# The basics of computer networking

## Addresses and subnets

### IPv4 and IPv6

Generally speaking, an IP address is a location specified by a number of bits. In terms of IPv4, 32 bits are used and in terms of IPv6, 128 bits are used. An IPv4 address looks like 127.0.0.1 and an IPv6 address looks like 0:0:0:0:0:0:0:1. These are both loopback addresses, this means that these loop back to the same computer.

Since IPv6 addresses are generally pretty long, there are some shortening rules that you can apply, these are

1. You can remove a string of zeros and `:` from anywhere in the IPv6 address one time and replace it with `::`.
2. You can remove any leading zeros in each section of the IPv6 address, for example the `0004` in `0001:0002:0003:0004:0005:0006:0007:0008` can be shortened to `1:2:3:4:5:6:7:8`.

Let's consider the loopback address, `0000:0000:0000:0000:0000:0000:0000:0001` and the shortened version, `::1`. Starting with rule #2, we get `0:0:0:0:0:0:0:1` and then using rule #1, we get `::1`.

### Subnets

A set of IP addresses can further divided into subnetworks. A subnet is a set of IP addresses that are all in the same network. For example, the set of IP addresses specified by 127.x.x.x for x in [0, 255] is the subnet of IP addresses that are all on the same network as the loopback address. Generally subnets are specified by using a notation called the CIDR notation. Instead of writing "127.x.x.x for x in [0, 255]" you can write "127.0.0.0/8" which means that the subnet is the set of all IP addresses that have 127 as the first 8 bits.

Commonly, the host IP address, 127.0.0.1 and the subnet is combined into a single notation like 127.0.0.1/8. This provides the address as well as tells you what the subnet specification is.

### Well known IP addresses and ranges

- 8.8.8.8/32 is Google's public DNS server
- 8.8.4.4/32 is another Google public DNS server
- 127.0.0.1/8 is the range of loopback addresses
- 169.254.0.1/16 are the range of IP addresses that a computer will assign itself when it is connected to a network but it has not been assigned a specific IP address.
- ::1/128 is the IPv6 loopback address space
- FE80::/10 is the range of self-assigned IPv6 addresses
- 2001:4860:4860::8888/32 is Google's public IPv6 DNS server
- 2001:4860:4860::8844/32 is another one of Google's public IPv6 DNS servers

You can also find well known DNS servers specified by both IPv4 and IPv6 addresses from CloudFlare, Cisco OpenDNS, and Quad9.

## Protocols

A protocol is a set of standardized rules for exchanging information over a network. Generally, we'll be talking about communication protocols, but there are other classes of protocols, like security protocols. Within communication protocols, there are protocols that maintain their connection and ones that don't. We will be talking about common protocols that we'll hear in the context of networking below.

### Internet Protocol

The Internet Protocol establishes a set of common rules for carrying datagrams over a particular network. It is responsible for establishing and addressing hosts, serialization and deserialization of data, and routing the data to the correct destination over an internet protocol network. This protocol serves as the base that the whole internet is built on.

### Transmission Control Protocol

Transmission Control Protocol is responsible for establishing and maintaining connections between hosts and transferring large chunks of data in a reliable, ordered, error checked way from one host to another. Commonly, TCP is used in conjunction with IP and forms the TCP/IP protocol suite. TCP uses the famous SYN-SYN-ACK-ACK 3-way handshake method for establishing connections to servers. This is where one host sends a `SYN`, the host on the other end replies with a `SYN-ACK` and then finally the initial host replies with an `ACK` to complete the connection.

### User Datagram Protocol

User Datagram Protocol is used when establishing a connecction is not necessary to send data. This is a fairly light protocol in the sense that there aren't a lot of mechanisms provided for connecting to a host or keeping the connection. This protocol is commonly used for things like DNS or NTP or as a way to bootstrap more complex protocols.

### Hypertext Transfer Protocol

Hypertext Transfer Protocol is the one that most people are most familiar with, this application protocol holds up the internet as we know it. Commonly associated with API endpoints, verbs like `GET` or `POST`, and status codes like `200` or `404`. It contains a series of instructions on how to connect to a particular host, transfer data, maintain connections, and receive content.

## OSI stack
