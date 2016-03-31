#!/bin/bash
# 防SSH暴力破解
#set -xv
DEFINE=20	#Password failed define
LIMIT=5		#User name failed limit
current_month=`date +%b`
current_day=`date +%d`
systype=`awk 'NR==1 {print $1}' /etc/issue`
CentOS_log="/var/log/secure"
Ubuntu_log="/var/log/auth.log"
log=`eval echo '\$'"$systype"_log`
# SSH crack root
	awk -v current_month="$current_month" '$1 ~ current_month && /Failed/ && /root/{print $(NF-3)}' "$log" | grep -E -o '[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?'|sort|uniq -c|awk '{print $2"="$1;}'  >/root/black.txt
	for i in `cat  /root/black.txt`
	  do
        	IP=`echo $i | awk -F= '{print $1}'`
	        NUM=`echo $i | awk -F= '{print $2}'`
	if [ $NUM -gt $DEFINE ];then
		grep $IP /root/white.txt > /dev/null
		if [ $? -gt 0 ];then		
			grep $IP /etc/hosts.deny > /dev/null
			if [ $? -gt 0 ];then
				echo "sshd:$IP" >> /etc/hosts.deny
			fi
		fi		
	fi
	done
# SSH guess username and password
	awk -v current_month="$current_month" -v current_day="$current_day" '$1 ~ current_month && $2 ~ current_day &&  /invalid user/ && /Failed/ {print $(NF-3)}' $log | sort |uniq -c | sort -nr |awk '{print $2"="$1}' >/root/try_crack_user.txt

	for j in `cat /root/try_crack_user.txt`
	do
		Ip=`echo $j | awk -F "=" '{print $1}'`
		Num=`echo $j |awk -F "=" '{print $2}'`
	if [ $Num -gt $LIMIT ];then 
		grep $Ip /root/white.txt > /dev/null
		if [ $? -gt 0 ];then
			grep $Ip /etc/hosts.deny >/dev/null
				if [ $? -gt 0 ];then
					echo "sshd:$Ip" >> /etc/hosts.deny
				fi
		fi
	fi
	done
