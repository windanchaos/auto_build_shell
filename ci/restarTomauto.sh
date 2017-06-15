#!/bin/sh
#结束tomcat进程
#设置环境变量
source /etc/profile
cd ~/ArhasMK
echo "执行时间:"`date`
history=`git log --since=9.hours -p . |grep diff |awk '{print $4}' |awk -F 'b/' '{print $2}'|sort -u|awk -F '/' '{print $1}'|sort -u`
arr=(`echo $history`)
if [ ${#arr[@]} -gt 0 ];then
	kill -9 ${k}`ps -fe |grep tomcat |awk '{print $2}'|head -3`
#开启tomcat
	cd /arthas/servers01/apache-tomcat-8.5.4-80/bin
	./startup.sh
else
	echo "Today ,there is no new code pulled from TFS"
fi
