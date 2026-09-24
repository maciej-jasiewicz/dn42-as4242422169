# Notes

Commands I use on the router and a few things that are easy to forget. The output below is from 24 September 2026, trimmed, with my router ID replaced.

## WireGuard

```routeros
/interface/wireguard/peers/print detail
```

`last-handshake` is the thing to look at. A WireGuard interface shows `R` (running) even when the other end is gone. BGP keepalives go out every minute, so the handshake renews about every two minutes. Anything much older than that means the tunnel is not working.

| Tunnel | rx | tx | last handshake |
|---|---|---|---|
| `wg-gload-de2` | 6.9 MiB | 2655.2 KiB | 1m42s |
| `wg-gload-fr1` | 7.3 MiB | 2377.5 KiB | 1m14s |
| `wg-gload-uk1` | 7.0 MiB | 2246.3 KiB | 1m10s |

The counters start at the reboot, about 12 hours earlier.

Link-local through one tunnel:

```routeros
/ping fe80::ade0 interface=wg-gload-de2 count=3
```

## BGP

```routeros
/routing/bgp/session/print
/routing/bgp/connection/print
```

Sessions show up as `<connection>-1`. The fr1 session:

```
 0 E name="bgp-gload-fr1-1" instance=dn42-instance
     remote.address=fe80::ade0%wg-gload-fr1 .as=4242423914 .id=172.20.53.102
     .capabilities=mp,rr,enhe,em,gr,as4,err,llgr,fqdn .afi=ip,ipv6
     .hold-time=4m .messages=26622 .bytes=4928192 .gr-time=120 .eor=ipv6
     local.address=fe80::2169%wg-gload-fr1 .as=4242422169 .id=<ROUTER_ID>
     .cluster-id=<ROUTER_ID> .capabilities=mp,rr,enhe,gr,as4 .afi=ipv6
     .messages=750 .bytes=14358 .eor=""
     output.procid=20 .filter-chain=dn42-out
     input.procid=20 .filter=dn42-in ebgp
     hold-time=3m keepalive-time=1m uptime=12h25m17s330ms
     last-started=2026-09-23 19:08:07 prefix-count=1275
```

de2 and uk1 look the same apart from the names, Kioubit's router ID, the counters and the times.

- Kioubit offers a 4m hold time and I use the default 3m, so the session runs 3m/1m.
- They offer `ip,ipv6`. The connection is `afi=ipv6`, so the session only carries IPv6 unicast.
- I sent 750 messages (14 KB) in 12h25m. That is almost entirely keepalives, since there is only one prefix to announce.
- Here `last-started` is off: it says 2026-09-23 19:08, but the router booted around 09:24 on the 24th. `uptime` is right.
- If `prefix-count` differs between the three sessions, the problem is on that Kioubit node.

## Routes

```routeros
/ipv6/route/print where dst-address=fd14:e78e:db29::/48
/ipv6/route/print count-only where bgp && active
/routing/route/print detail where dst-address=<DN42_PREFIX>
```

The first one has to show the blackhole route as active. Without it nothing gets announced. The last one shows the path from each session. `contribution=filtered` means `dn42-in` rejected it. Host routes, anything shorter than /44 and anything outside `fd00::/8` are rejected on purpose.

`/routing/bgp/advertisements/print` stays empty unless `output.keep-sent-attributes=yes` is set on the connection.

## Ping and traceroute into DN42

```routeros
/ping <DN42_ADDRESS> src-address=fd14:e78e:db29::1
/tool/traceroute <DN42_ADDRESS> src-address=fd14:e78e:db29::1
```

The tunnels only have link-local addresses, so the source address has to come from another interface. `src-address` makes sure it is the DN42 one.

The default IPv6 accept rules aren't tied to an interface, so they also accept ICMPv6 and UDP traceroute coming from the tunnels. That is why the router answers ping and traceroute from DN42.

## MTU

The PPPoE MTU is 1492. WireGuard over IPv4 adds 60 bytes (20 IP + 8 UDP + 32 WireGuard), so the largest inner packet is 1432 and 1420 leaves 12 bytes spare. Over an IPv6 underlay the overhead is 80 bytes and 1420 would not fit. On 24 September all three endpoints resolved to IPv4, so that didn't apply.

```routeros
/ping <ENDPOINT_IPV4> size=1480 do-not-fragment
```

## Adding a peering

1. WireGuard interface (MTU 1420) and peer with `allowed-address=::/0,0.0.0.0/0`.
2. `fe80::2169/64` on the interface.
3. Interface into the `DN42` list.
4. Listen port into "Allow DN42 WireGuard".
5. BGP connection with the `%interface` addresses, `dn42-in`, `dn42-out` and `redistribute=static`.
