# DN42 tunnels, cut from the router export (RouterOS 7.23.7).
# Replaced: listen ports, Kioubit's keys and endpoints. Default values and the
# client-* helper fields on the peers are left out.

/interface list
add comment="DN42 peerings" name=DN42

/interface wireguard
add listen-port=<LISTEN_PORT_DE2> mtu=1420 name=wg-gload-de2
add listen-port=<LISTEN_PORT_FR1> mtu=1420 name=wg-gload-fr1
add listen-port=<LISTEN_PORT_UK1> mtu=1420 name=wg-gload-uk1

# One peer per interface, so allowed-address can be "any" and BGP decides
# where traffic goes. fr1 and uk1 really do share one public key on Kioubit's side.
/interface wireguard peers
add allowed-address=::/0,0.0.0.0/0 endpoint-address=<ENDPOINT_DE2> \
    endpoint-port=<ENDPOINT_PORT_DE2> interface=wg-gload-de2 name=wg-gload-de2 \
    public-key="<KIOUBIT_KEY_DE2>"
add allowed-address=::/0,0.0.0.0/0 endpoint-address=<ENDPOINT_UK1> \
    endpoint-port=<ENDPOINT_PORT_UK1> interface=wg-gload-uk1 name=wg-gload-uk1 \
    public-key="<KIOUBIT_KEY_FR1_UK1>"
add allowed-address=::/0,0.0.0.0/0 endpoint-address=<ENDPOINT_FR1> \
    endpoint-port=<ENDPOINT_PORT_FR1> interface=wg-gload-fr1 name=wg-gload-fr1 \
    public-key="<KIOUBIT_KEY_FR1_UK1>"

# Static link-local for the BGP sessions (2169 = end of the ASN). RouterOS also
# adds a random fe80:: address to each tunnel, so bgp.rsc sets local.address.
/ipv6 address
add address=fe80::2169/64 advertise=no interface=wg-gload-de2
add address=fe80::2169/64 advertise=no interface=wg-gload-uk1
add address=fe80::2169/64 advertise=no interface=wg-gload-fr1

/interface list member
add interface=wg-gload-de2 list=DN42
add interface=wg-gload-fr1 list=DN42
add interface=wg-gload-uk1 list=DN42
