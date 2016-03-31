#!/bin/bash

#定义变量
log=err_log
cmd_scripts=scripts.conf
cfg_file=server_ip.conf

#判断是否有重名日志文件err_log存在
[ -e err_log ] && rm -i err_log

#获取ip 端口并执行cmd_scripts
while read LINE
do
    ip=`echo "$LINE" | grep -v '^#' | grep -v '^$' | awk '{print $1}'`
    port=`echo "$LINE"|awk '{print $2}'`
    if [ -z $ip ];then
    echo >/dev/null
    else
        echo $ip:$port
        ssh -p $port unix@$ip "bash" <$cmd_scripts 2>> $log
        [ $? -ne 0 ] && echo "$ip 执行失败！"
fi
done < $cfg_file

#结束语
end() {
echo
echo -----------------
echo "Tasks finished~"
echo -----------------
}

#
if [ $? -eq 0 ];then
    end
else
    echo "Failed" && exit
fi

#判断错误日志文件是否为空，若为空则删除
if [ ! -s err_log ];then
    rm -f err_log
else 
    echo "Please check the $log file for more details !"
fi
