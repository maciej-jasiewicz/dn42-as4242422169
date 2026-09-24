# AS4242422169

My DN42 network: the public part of the router configuration and a few notes. General DN42 background is on [dn42.dev](https://dn42.dev/).

Everything runs on one MikroTik hAP ax³ with RouterOS 7.23.7 (long-term). The same router is also my home router, so most of its configuration is Wi-Fi, DHCP, NAT and other home things. Only the DN42 part is here.

## Setup

- ASN `AS4242422169`, prefix `fd14:e78e:db29::/48`. The `route6` object in the registry has `max-length: 48`.
- IPv6 only. I don't have a DN42 IPv4 allocation.
- Three peerings, all with Kioubit (AS4242423914): one to each of their nodes `de2`, `fr1` and `uk1`.
- Each peering has its own WireGuard interface (MTU 1420) over my PPPoE uplink. eBGP runs inside the tunnel between link-local addresses: `fe80::2169` on my side, `fe80::ade0` on theirs.
- The router's DN42 address is `fd14:e78e:db29::1/128` on the LAN bridge. It is the only address from the /48 in use. LAN clients don't get DN42 addresses.

On 24 September 2026, about 12 hours after a reboot, all three sessions were up with 1275 prefixes each. The hAP was at 1% CPU with 610 of 1024 MiB free.

## Routing policy

I announce my /48 and nothing else, and I only accept prefixes that look like DN42 allocations:

```routeros
/routing filter rule
add chain=dn42-in rule="if (dst in fd00::/8 && dst-len >= 44 && dst-len <= 64) { accept; } else { reject; }"
add chain=dn42-out rule="if (dst == fd14:e78e:db29::/48) { accept; } else { reject; }"
```

The /48 exists on the router only as a static blackhole route. `output.redistribute=static` on each connection picks it up, and `dn42-out` lets exactly that prefix through. The import rule is the `fd00::/8{44,64}` check from the [DN42 BIRD 2 guide](https://dn42.dev/howto/Bird2).

There is no VRF: DN42 routes go into `main` next to my normal routes, so `dn42-in` is also what stops a peer from handing me a default route or a public prefix.

## Firewall

There are four DN42 rules on top of the default ones, plus some home rules that don't touch DN42 traffic. The WireGuard rule matches only the listen ports, because those packets come in on the uplink. The other three match the interface list `DN42`.

- IPv4 input: accept UDP to the three WireGuard listen ports.
- IPv6 input: accept TCP/179 from `fe80::/10` on DN42 interfaces.
- IPv6 forward: accept `fd00::/8` to `fd00::/8` between DN42 interfaces. The comment on the router says "transit", but I only announce my /48, so nothing should need it.
- IPv4 forward: drop everything that comes in on a DN42 interface. Apart from invalid packets, the default IPv4 forward chain only drops new connections from WAN, and the WireGuard peers allow `0.0.0.0/0`. Without it, the router would forward IPv4 from a tunnel into the LAN or masquerade it out of my uplink.

## Files

- [routeros/wireguard.rsc](routeros/wireguard.rsc): tunnels, peers, link-local addresses
- [routeros/bgp.rsc](routeros/bgp.rsc): DN42 address, blackhole route, BGP instance, connections, filters
- [routeros/firewall.rsc](routeros/firewall.rsc): the four rules and where they sit
- [notes.md](notes.md): commands, trimmed output from the router, a few gotchas

The `.rsc` files are cut from the router's export with default values removed. `<ANGLE_BRACKETS>` mark replaced values: WireGuard keys, endpoints, listen ports and the BGP router ID. Everything else is as on the router. I haven't imported them as a set on a clean router, so treat them as a reference, not an installer.

## Gaps

- All three sessions go to Kioubit, over one uplink, from one router.
- No ROA/RPKI validation and no prefix limit. `dn42-in` also doesn't reject more-specifics of my own /48.
- No monitoring. [notes.md](notes.md) has the commands for checking things by hand.
