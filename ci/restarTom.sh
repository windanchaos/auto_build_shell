#!/bin/sh
echo "执行时间:"`date`
#结束tomcat进程
kill -9 ${k}`ps -fe |grep servers/ |awk '{print $2}'|head -3`
#开启tomcat
cd /arthas/servers/apache-tomcat-8.5.4-80/bin
./startup.sh

