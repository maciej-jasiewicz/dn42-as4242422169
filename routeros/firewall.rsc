# The DN42 rules from the router's firewall (RouterOS 7.23.7).
# Replaced: the WireGuard listen ports. Rule comments are as on the router.
# The rest of the firewall (defconf plus home rules) isn't here. The comment
# above each rule says where it sits.

/ip firewall filter
# input: directly above "defconf: drop all not coming from LAN"
add action=accept chain=input comment="Allow DN42 WireGuard" \
    dst-port=<LISTEN_PORT_DE2>,<LISTEN_PORT_UK1>,<LISTEN_PORT_FR1> protocol=udp
# forward: last rule. Nothing in defconf drops new IPv4 coming in on a tunnel.
add action=drop chain=forward comment=repair-block-ipv4-from-dn42 \
    in-interface-list=DN42

/ipv6 firewall filter
# input: directly above "defconf: drop everything else not coming from LAN"
add action=accept chain=input comment="DN42: allow BGP from peers" dst-port=179 \
    in-interface-list=DN42 protocol=tcp src-address=fe80::/10
# forward: first rule, above fasttrack6 and the defconf drops
add action=accept chain=forward comment="DN42: allow IPv6 transit" \
    dst-address=fd00::/8 in-interface-list=DN42 out-interface-list=DN42 \
    src-address=fd00::/8
