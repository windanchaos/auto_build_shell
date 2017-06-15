#!/bin/sh
echo "执行时间:"`date`
source /etc/profile
tail -f /arthas/servers/apache-tomcat-8.5.4-80/logs/catalina.out

