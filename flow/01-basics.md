# The basics of computer networking

## Addresses and subnets

### IPv4 and IPv6

Generally speaking, an IP address is a location specified by a number of bits. In terms of IPv4, 32 bits are used and in terms of IPv6, 128 bits are used. An IPv4 address looks like 127.0.0.1 and an IPv6 address looks like 0:0:0:0:0:0:0:1. These are both loopback addresses, this means that these loop back to the same computer.

Since IPv6 addresses are generally pretty long, there are some shortening rules that you can apply, these are

1. You can remove a string of zeros and `:` from anywhere in the IPv6 address one time and replace it with `::`.
2. You can remove any leading zeros in each section of the IPv6 address, for example the `0004` in `0001:0002:0003:0004:0005:0006:0007:0008` can be shortened to `1:2:3:4:5:6:7:8`.

Let's consider the loopback address, `0000:0000:0000:0000:0000:0000:0000:0001` and the shortened version, `::1`. Starting with rule #2, we get `0:0:0:0:0:0:0:1` and then using rule #1, we get `::1`.

## Protocols

## OSI stack
