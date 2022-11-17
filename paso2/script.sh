dnsIp=$1                                             # 192.168.1.2
dir=$(echo $1 | cut -d '.' -f-3)                     # 192.168.1
rev=$(echo $1 | tac -s. | tail -1 | cut -d '.' -f-3) # 1.168.192
lugar=$2                                              # aula104.local


apt-get update
apt-get install -y bind9 bind9utils bind9-doc
 
cat <<EOF >/etc/bind/named.conf.options
acl "allowed" {
    $dir.0/24;
};

options {
    directory "/var/cache/bind";
    dnssec-validation auto;  // default

    listen-on-v6 { any; };
    forwarders { 1.1.1.1;  1.0.0.1;  };
};
EOF

cat <<EOF >/etc/bind/named.conf.local
zone $lugar {
        type master;
        file "/var/lib/bind/$lugar";
        };
zone "$rev.in-addr.arpa" {
        type master;
        file "/var/lib/bind/$dir.rev";
        };
EOF

cat <<EOF >/var/lib/bind/$lugar
\$TTL 3600      ; Este es el tiempo, en segundos, que un registro de recurso de lugar es válido
$lugar.     IN      SOA     ns.$lugar. santi.$lugar. (
    3           ; n <serial-number> Un valor incrementado cada vez que se cambia el archivo de lugar 
    7200        ; 2 horas <time-to-refresh> tiempo de espera de un esclavo antes de preguntar al maestro si se han realizado cambios
    3600        ; 1 hora <time-to-retry>  tiempo de espera antes de emitir una petición de actualización, si el maestro no responde.
    604800      ; 1 semana <time-to-expire> Tiempo que guarda la lugar si el servidor maestro no ha respondido. 
    86400 )     ; 1 día <minimum-TTL> Tiempo que otros servidores de nombres guardan en caché la información de lugar.

; Registro NameServer de la lugar, el cual anuncia los nombres de servidores con autoridad.
$lugar.          IN      NS      ns.$lugar. ; debe ser un FQDN.

; Registros Address FQDN y no FQDN
ns.$lugar.       IN      A       $dnsIp
nginx           IN      A       $dir.10
apache1.$lugar.  IN      A       $dir.11
apache2         IN      A       $dir.12

; Registros ALIAS FQDN y no FQDN
sv1             IN      CNAME   apache1
sv2             IN      CNAME   apache2
ns1.$lugar.      IN      CNAME   ns
ns2.$lugar.      IN      CNAME   ns
proxy           IN      CNAME   nginx
balancer        IN      CNAME   nginx
EOF

cat <<EOF >/var/lib/bind/$dir.rev
\$ttl 3600
$rev.in-addr.arpa.  IN      SOA     ns.$lugar. santi.$lugar. (
    3
    7200
    3600
    604800
    86400 )
; Registros NS
$rev.in-addr.arpa.  IN      NS      ns.$lugar.

; Registros PUNTEROS
2   IN  PTR dns
10  IN  PTR nginx
11  IN  PTR apache1
12  IN  PTR apache2
EOF

cp /etc/resolv.conf{,.bak}
cat <<EOF >/etc/resolv.conf
nameserver 127.0.0.1
domain $lugar
EOF

named-checkconf
named-checkconf /etc/bind/named.conf.options
named-checkzone $lugar /var/lib/bind/$lugar
named-checkzone $rev.in-addr.arpa /var/lib/bind/$dir.rev
sudo systemctl restart bind9
