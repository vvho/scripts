#!/bin/bash

/sbin/modprobe ip_tables
/sbin/modprobe iptable_nat
/sbin/modprobe iptable_filter
/sbin/modprobe xt_state

iptables -t filter -F
iptables -t filter -X
iptables -t filter -Z

iptables -t mangle -F
iptables -t mangle -X
iptables -t mangle -Z

iptables -t nat -F
iptables -t nat -X
iptables -t nat -Z

#Audit drop|accept|reject  records
iptables -t filter -N AUDIT_DROP
iptables -t filter -A AUDIT_DROP -j AUDIT --type drop
iptables -t filter -A AUDIT_DROP -j DROP

# Drop 302 redirect packets
#iptables -t filter -A INPUT -p tcp --sport 80 -m string --string "Location:http//" --algo bm -j DROP

# Manage ttl attribute in Mangle table 
# iptables -t mangle -A PREROUTING -m ttl --ttl-eq 128 -j DROP

# u32 module
# DROP packets TTL=128  
#iptables -t filter -A INPUT -p tcp -m u32 --u32 "8&0xFF000000=2147483648" -j DROP
#iptables -t filter -A INPUT -p tcp -m u32 ! --u32 "8&0xFF000000=2147483648" -j DROP

# Log ttl=128
#iptables -t filter -A INPUT -p tcp -m u32 --u32 "5&0xFF=128" -j LOG --log-level info --log-prefix debug 

# AUDIT_DROP rule,see log in /var/log/audit/audit.log
#iptables -t filter -A INPUT -p all -m u32 --u32 "5&0xFF=127:129" -j AUDIT_DROP
#iptables -t filter -A INPUT -p all -m u32 --u32 "5&0xFF=127,129" -j DROP
#iptables -t filter -A INPUT -p tcp -m u32 --u32 "5&0xFF=0x80" -j DROP

# Drop if ip head length equal 20 (header length 1byte,value 5)
#iptables -t filter -A INPUT -p tcp -m u32 --u32 "0>>24&0x0F=5" -j AUDIT_DROP
#iptables -t filter -A INPUT -p tcp -m u32 --u32 "0>>22&0x3C=20" -j AUDIT_DROP

#Skip IP Header
#iptables -t filter -A INPUT -p tcp -m u32 --u32 "0>>22&0x3C@Start&Mask=Value" -j DROP

#Audit dropped packet from sport 443
#iptables -t filter -A INPUT -p tcp -m u32 --u32 "0>>22&0x3C@0&0xFFFF0000=29032448" -j AUDIT_DROP
