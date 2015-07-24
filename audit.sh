#!/bin/bash
#Date:2015-07-07
#It records commands execute by user in /var/log/.audit/
#Version 0.0.1
#Author:lxx
set -u
#判断用户身份
[ "$UID" -ne 0 ] && echo "Permission denied,you need to be root." &&  exit

#判断sh指向的shell，修改为bash
[ "`readlink /bin/sh`" != "/bin/bash" ] && rm -f /bin/sh \
&& ln -s /bin/bash /bin/sh

#禁用其他类型的shell
chmod 500 /bin/dash /bin/mksh &>/dev/null

#判断创建文件夹，并作权限修改
export AUDIT_DIR="/var/log/.audit" &>/dev/null
[ ! -d "$AUDIT_DIR" ] && \
{
mkdir -p "$AUDIT_DIR"
chmod 777 $AUDIT_DIR
chmod +t $AUDIT_DIR
}
#test audit.sh是否已经存在
if [ -f /etc/profile.d/audit.sh ];
then
rm -f /etc/profile.d/audit.sh
fi

#写入/etc/profile.d/audit.sh
cat >>/etc/profile.d/audit.sh<<'_EOF_'
#!/bin/bash
REAL_USER=$(who -u am i | awk '{print $1}')
if [ ! -d "/var/log/.audit/$REAL_USER" ];then
mkdir -p "/var/log/.audit/$REAL_USER"
chmod 300 "/var/log/.audit/$REAL_USER"
fi
#unset 历史变量
export HISTCONTROL="" &>/dev/null
export HISTIGNORE="" &>/dev/null
readonly HISTCONTROL
readonly HISTIGNORE

#注释掉用户目录下的HISTCONTROL
sed -i '/HISTCONTROL=/ s/^[^#]/#&/' ~/.bashrc

#历史命令追加&命令不换行
shopt -s histappend
shopt -s cmdhist

export HISTORY_FILE="/var/log/.audit/$REAL_USER/.bash_history-`date +%F`" &>/dev/null
export HISTTIMEFORMAT="%Y/%m/%d %T " &>/dev/null

#设置变量只读
readonly HISTTIMEFORMAT
readonly HISTORY_FILE

export PROMPT_COMMAND='{ USER=$(who -u am i | awk "{print \$1}");PTS=$(who -u am i | awk "{print \$2}");LOGIN_TIME=$(who -u am i|awk "{print \$3,\$4}");PID=$(who -u am i | awk "{print \$(NF-1)}");IP=$(who -u am i | awk "{print \$NF}");EUSER=$(whoami);CURRENT_COMMAND=$(history 2|awk "NR==2 {\$1=\"\";\$2=\"\";\$3=\"\";print \$0}");COMMAND_ID=$(history 2|awk "NR==2 {print \$1}");COMMAND_TIME=$(history 2 | awk "NR==2 {print \$3}");LAST_COMMAND=$(history 2|awk "NR==1 {\$1=\"\";\$2=\"\";\$3=\"\";print \$0}");LAST_COMMAND_ID=$(history 2|awk "NR==1 {print \$1}");COMMAND_TIME=$(history 2 | awk "NR==2 {print \$3}");if [ "${COMMAND_ID}x" != "${LAST_COMMAND_ID}x" ];then echo "$USER      $PTS        $LOGIN_TIME  $IP   EUSE:$EUSER   $COMMAND_ID    [$CURRENT_COMMAND  ]    $COMMAND_TIME";fi; } >>$HISTORY_FILE' &>/dev/null

readonly PROMPT_COMMAND
_EOF_
