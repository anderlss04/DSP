enable-bind9.sh es como lo ha llamdo santi hay que hacer referencia a el desde el vagrant file

-------------------------------------------------------------
DNSIP=$1
apt-get update
apt-get install -y bind9 bind9utils bind9-doc
 
cat <<EOF >/etc/bind/named.conf.options
acl "allowed" {
    192.168.1.0/24;
};

options {
    directory "/var/cache/bind";
    dnssec-validation auto;

    listen-on-v6 { any; };
    forwarders { 1.1.1.1;  1.0.0.1;  };
};
EOF                                             

cat <<EOF >/etc/bind/named.conf.local
zone "dominio.local" {
        type master;
        file "/var/lib/bind/dominio.local";
        };
zone "1.168.192.in-addr.arpa" IN{
        type master;
        file "/var/lib/bind/dominio.local-rev";
        };
EOF

cat <<EOF >/var/lib/bind/dominio.local
$TTL 3600
dominio.local.     IN      SOA     nsGon.dominio.local. root.dominio.local. (
                3            ; serial
                7200         ; refresh after 2 hours
                3600         ; retry after 1 hour
                604800       ; expire after 1 week
                86400 )      ; minimum TTL of 1 day

dominio.local.          IN      NS      nsGon.dominio.local.
nsGon.dominio.local.       IN      A       $DNSIP
; aqui pones los hosts
EOF

cat <<EOF >/var/lib/bind/dominio.local-rev
$ttl 3600
1.168.192.in-addr.arpa.  IN      SOA     nsGon.dominio.local. root.dominio.local. (
                3            ; serial
                7200         ; refresh after 2 hours
                3600         ; retry after 1 hour
                604800       ; expire after 1 week
                86400 )      ; minimum TTL of 1 day
1.168.192.in-addr.arpa.  IN      NS      nsGon.dominio.local.
; aqui pones los hosts inversos

EOF

cp /etc/resolv.conf{,.bak}
cat <<EOF >/etc/resolv.conf
nameserver 127.0.0.1
domain dominio.local
EOF