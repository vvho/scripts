#!/bin/bash
set -u
# Date:2016-03-30

# Root or sudo authentication.
[ $UID -ne 0 ] && echo "Permission denied! You need to be root." && exit

# Variables 
# Set wan/lan interface
var_set() {
read -p "ssh port(Press Enter for default): " SSH_PORT
#read -p "Your Wan Interface(Press Enter to use eth1 as default): " WANIF
#read -p "Your Lan Interface(Press Enter to use eth0 as default): " LANIF
SSH_PORT=${SSH_PORT:-22}
}

var_set

function warning() {
        echo -e "Here are the settings:\n SSH:$SSH_PORT"
}
warning
read -p "Continue y/n?" CHOICE
echo
[ "${CHOICE}x" == "yx" -o "${CHOICE}x" == "Yx" ] || exit
echo "Loading modules..."
/sbin/modprobe ip_tables
/sbin/modprobe iptable_nat
/sbin/modprobe iptable_filter
/sbin/modprobe ip_conntrack
/sbin/modprobe ip_conntrack_ftp
/sbin/modprobe ip_nat_ftp
/sbin/modprobe ipt_limit
/sbin/modprobe ipt_connlimit
/sbin/modprobe ipt_LOG
/sbin/modprobe xt_state
echo "Modules loading complete."

# Empty exist rules.
echo "Flush deprecated firewall rules..."

iptables -t filter -F
iptables -t filter -X
iptables -t filter -Z

iptables -t nat -F
iptables -t nat -X
iptables -t nat -Z

#Default Policy
echo "Set default policy..."
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

echo "Setting rules for ssh,http,dns..."
# Drop INVALID
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A OUTPUT -m state --state INVALID -j DROP
iptables -A FORWARD -m state --state INVALID -j DROP

# Accept ESTABLISHED,RELATED
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Interface lo
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# ACCEPT ICMP
iptables -A INPUT -m icmp -p icmp --icmp-type echo-request -m limit --limit 6/m --limit-burst 10 -m state --state NEW -j ACCEPT
iptables -A INPUT -m icmp -p icmp --icmp-type echo-request -j DROP
# Ping Other host
iptables -A OUTPUT -m icmp -p icmp --icmp-type echo-request -m state --state NEW -j ACCEPT

# Open DNS port
iptables -A OUTPUT -p udp --dport 53 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -m state --state NEW -j ACCEPT

# SSH:Allow remote connect to local <with limit>
iptables -A INPUT -p tcp --dport $SSH_PORT -m limit --limit 3/m --limit-burst 5 -j ACCEPT
iptables -A INPUT -p tcp --dport $SSH_PORT -m limit -j DROP

# SSH:connlimit
iptables -A INPUT -p tcp --dport $SSH_PORT -m connlimit --connlimit-above 3 -j DROP
iptables -A INPUT -p tcp --dport $SSH_PORT -m state --state NEW -m recent --set --name SSH

# Allow local connect to remote
iptables -A OUTPUT -p tcp -m multiport --dports 22,80,$SSH_PORT -m state --state NEW -j ACCEPT
# iptables -A INPUT -p tcp --sport 22212 -m state --state ESTABLISHED -j ACCEPT

# Single ip connlimit
iptables -A INPUT -p tcp --dport 80 -m connlimit ! --connlimit-above 30 -j ACCEPT

# Defend port scan syn attack
iptables -A INPUT -p tcp --syn -m connlimit --connlimit-above 15 -j DROP
#Or iptables -A FORWARD -p tcp --syn -m connlimit --connlimit-above 15 -j DROP

# Disable Rerverse shell <Put this rule at the bottom of OUTPUT chain.>
iptables -A OUTPUT -m state --state NEW -j DROP

clear

echo ------------------------------------
echo "防火墙规则设置结束."
