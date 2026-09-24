# BGP for AS4242422169, cut from the router export (RouterOS 7.23.7).
# Replaced: the router ID. Default values left out.

/ipv6 address
add address=fd14:e78e:db29::1/128 advertise=no interface=bridge

# Announced through redistribute=static on the connections below.
/ipv6 route
add blackhole dst-address=fd14:e78e:db29::/48

/routing bgp instance
add as=4242422169/0 name=dn42-instance router-id=<ROUTER_ID>

# The %interface suffix has to name the same tunnel on both addresses.
/routing bgp connection
add afi=ipv6 as=4242422169 input.filter=dn42-in instance=dn42-instance \
    local.address=fe80::2169%wg-gload-de2 .role=ebgp name=bgp-gload-de2 \
    output.filter-chain=dn42-out .redistribute=static \
    remote.address=fe80::ade0%wg-gload-de2/128 .as=4242423914 routing-table=main
add afi=ipv6 as=4242422169 input.filter=dn42-in instance=dn42-instance \
    local.address=fe80::2169%wg-gload-uk1 .role=ebgp name=bgp-gload-uk1 \
    output.filter-chain=dn42-out .redistribute=static \
    remote.address=fe80::ade0%wg-gload-uk1/128 .as=4242423914 routing-table=main
add afi=ipv6 as=4242422169 input.filter=dn42-in instance=dn42-instance \
    local.address=fe80::2169%wg-gload-fr1 .role=ebgp name=bgp-gload-fr1 \
    output.filter-chain=dn42-out .redistribute=static \
    remote.address=fe80::ade0%wg-gload-fr1/128 .as=4242423914 routing-table=main

/routing filter rule
add chain=dn42-in rule="if (dst in fd00::/8 && dst-len >= 44 && dst-len <= 64) { accept; } else { reject; }"
add chain=dn42-out rule="if (dst == fd14:e78e:db29::/48) { accept; } else { reject; }"
