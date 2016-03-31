
#!/bin/bash

#Initialize System security setup

#set -xv
[ "$UID" -ne 0 ] && echo "Permission denied,you need to be root." && exit || echo "Ready to perform..."

#System Version

systype=`awk 'NR==1 {print $1}' /etc/issue`
echo "Your System is $systype"

#Backup

cp /etc/passwd{,.bak}
chattr +i /etc/passwd.bak

cp /etc/group /etc/group.bak
chattr +i /etc/group.bak

chattr -i /etc/passwd

chattr -i /etc/group 

users="adm lp shutdown halt uucp operator games gopher ftp" #Double ""

groups="adm lp uucp games dip"

#Lock each user in $users

for i in $users
do
sed -i "/^$i/ s/^$i/#$i/" /etc/passwd
done
for i in $users
    do 
     passwd --lock $i 2>/dev/null
done

#Comment group in $groups
for j in $groups
do
sed -i "/^$j/ s/^$j/#$j/" /etc/group
done     
echo "Users and Group Configuration complete!"
#pam module configuration only for centos
if [ "$systype"x == "CentOS"x ];then

#Forbbiden switch to root except users in group wheel
cp /etc/pam.d/su /etc/pam.d/su.bak
chattr +i /etc/pam.d/su.bak

sed -i '/pam_wheel.so/c  auth            sufficient        pam_wheel.so use_uid' /etc/pam.d/su

grep 'file=/etc/sudeny' /etc/pam.d/su 1>/dev/null || sed -i '/pam_wheel.so/a auth          required             pam_listfile.so onerr=fail item=user sense=deny file=/etc/sudeny' /etc/pam.d/su

grep '^root$' /etc/sudeny 2>/dev/null 1>&2 || echo "root" >>/etc/sudeny

grep 'SU_WHEEL_ONLY' /etc/login.defs 1>/dev/null || echo "SU_WHEEL_ONLY yes">>/etc/login.defs
echo "CentOS su configuration finish!"
fi

#backup 
cp /etc/login.defs{,.bak}
chattr +i /etc/login.defs.bak

#Password policy
logindef=/etc/login.defs
sed -i "/^[^#]*PASS_MAX_DAYS/c PASS_MAX_DAYS   60" "$logindef"
sed -i "/^[^#]*PASS_MIN_DAYS/c PASS_MIN_DAYS   10" "$logindef" 
sed -i "/^[^#]*PASS_WARN_AGE/c  PASS_WARN_AGE   7" "$logindef"
[ "$systype"x = "CentOS"x ] && sed -i "/^[^#]*PASS_MIN_LEN/c  PASS_MIN_LEN	8" "$logindef" 
echo "Password Policy settings have been done!"

#Auto logout 

cp /etc/profile{,.bak}
chattr +i /etc/profile.bak
grep 'TMOUT=300' /etc/profile 1>/dev/null || sed -i '/HISTSIZE=/a TMOUT=300' /etc/profile

#History command list limit
sed -i "/^[^#]*HISTSIZE=/c HISTSIZE=30" /etc/profile
source /etc/profile

#Login Info
[ -f /etc/issue ] && mv /etc/issue /etc/issue.bak && echo "Welcome!">/etc/issue
[ -f /etc/issue.net ] && mv  /etc/issue.net   /etc/issue.net.bak && echo "Welcome!">/etc/issue.net 

#backup
cp /etc/skel/.bash_logout{,.bak}
chattr +i /etc/skel/.bash_logout.bak

#Remove cmd history  while log_out

grep "$HOME/.bash_history" /etc/skel/.bash_logout 1>/dev/null || echo "rm -f $HOME/.bash_history">>/etc/skel/.bash_logout

#set ssh
cp /etc/ssh/sshd_config{,.bak}
chattr +i /etc/ssh/sshd_config.bak

#Make Port 22212 as Default
sed -i "/Port 22/a  Port 22212" /etc/ssh/sshd_config 

#Close GSSAPIAuthentication
sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config 

sed -i '/UseDNS/c UseDNS no' /etc/ssh/sshd_config #Do Not use DNS

#Disable empty password
sed -i '/PermitEmptyPasswords/c PermitEmptyPasswords no' /etc/ssh/sshd_config 

#Protocol 2 only
sed -i '/^Protocol /c Protocol 2' /etc/ssh/sshd_config

#Forbid Rhosts Authentication
sed -i '/IgnoreRhosts/c IgnoreRhosts yes' /etc/ssh/sshd_config

#Disallow root connection
sed -i '/PermitRootLogin/c PermitRootLogin no' /etc/ssh/sshd_config

#Max Auth tries
sed -i '/MaxAuthTries/c MaxAuthTries 3' /etc/ssh/sshd_config

echo "The SSH configuration is complete, restart it now!"
service sshd restart || service ssh restart
echo "`service sshd status || service ssh status`" 2>/dev/null

cp /etc/host.conf /etc/host.conf.bak
chattr +i /etc/host.conf.bak

sed -i '/multi/a nospoof on' /etc/host.conf
sed -i '/order/ s/^/#/' /etc/host.conf
sed -i '/order/a order bind,hosts' /etc/host.conf
echo "Host file configure complete!"

#Enrypt files as list
chattr +i /etc/passwd
chattr +i /etc/shadow
chattr +i /etc/group
chattr +i /etc/gshadow
chattr +i /etc/services  #可精简 
chmod 500 /bin/ps

#User commands limit
cat >>linux_command.txt <<EOF
/bin/ping
/usr/bin/vim
/bin/netstat
/usr/bin/tail
/usr/bin/less
/usr/bin/head
/usr/bin/last
/bin/cat
/bin/uname
/usr/bin/finger
/usr/bin/as
/usr/bin/who
/usr/bin/w
/usr/bin/locate
/usr/bin/whereis
/sbin/ifconfig
/usr/bin/which
/usr/bin/gcc
/usr/bin/make
/bin/rpm
EOF
for i in `cat linux_command.txt`
do
	chmod 700 "$i" 2>>cmd.log
done
rm linux_command.txt

#Service control
chmod -R 700 /etc/rc.d/init.d/*

#Remove SUID SGID
chmod a-s /usr/bin/chage
chmod a-s /usr/bin/gpasswd
chmod a-s /usr/bin/wall
chmod a-s /usr/bin/chfn
chmod a-s /usr/bin/chsh
chmod a-s /usr/bin/newgrp
chmod a-s /usr/bin/write
chmod a-s /usr/sbin/usernetctl
chmod a-s /bin/traceroute
chmod a-s /bin/mount
chmod a-s /bin/umount
chmod a-s /sbin/netreport

#Generate md5 value

cat >list<<EOF &&
/bin/ping
/usr/bin/finger
/usr/bin/who
/usr/bin/w
/usr/bin/locate
/usr/bin/whereis
/sbin/ifconfig
/bin/vi
/usr/bin/vim
/usr/bin/which
/usr/bin/gcc
/usr/bin/make
/bin/rpm
/bin/ps
EOF

for i in `cat list`
do
if [ ! -x $i ];then
echo
else
md5sum $i >> /var/log/`hostname`.log 2>&1
fi
done
#Copy md5 file
cp /var/log/`hostname`.log /var/log/`hostname`.log_`date +%Y-%m-%d`
cp /var/log/`hostname`.log /root/cmd_md5.txt

#Remove tmp file
rm -rf list

echo "The MD5 value of the commands were generated successfully~"

clear

echo  --------------------------------------------
echo "+ All the configuration has been completed ~+"
echo "+ Thank you ! =^_^=                         + " 
echo  --------------------------------------------
