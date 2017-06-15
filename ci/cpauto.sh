#!/bin/sh
#auto build when the code update in 1 hour
#created by bojiang@maike51.com
source /etc/profile
webents=(mk-aggregator mk-smart-webent mk-demon-webent mk-wm-msger mk-app-webent mk-job-webent mk-openApi mk-wm-webent mk-yum-webent mk-imgr-webent mk-uic-webent mk-qdragon-webent mk-sn-webent mk-intf-webent mk-kunlun-webent mk-imgr-rpc mk-yum-rpc mk-mdata-rpc mk-uic-rpc mk-sn-rpc)

echo "执行时间"`date`
cd ~/ArhasMK
history=`git log --since=9.hours -p . |grep diff |awk '{print $4}' |awk -F 'b/' '{print $2}'|sort -u`
arr=(`echo $history`) 
i=0
l=${#arr[@]}
while [ $i -lt $l ]
do
    h=${arr[$i]}
    webent=`echo $h|awk -F '/' '{print $1}'|sort -u`
    if [ "$webent" == "fontend-vue" ] || [ "$webent" == "mk-tra-data-mysql" ] || [ "$webent" == "mk-static" ];then
	unset arr[$i]
    fi
    let i++
done
for h in ${arr[@]} 
do
    filename=`echo $h |awk -F '.' '{print $2}'|sort -u`
    if [ "$filename" == "jsp"  ] || [ "$filename" == "css"  ] || [ "$filename" == "js" ];then
	filepath=`echo $h|awk -F 'webapp' '{print $2}'|sort -u`
	webent=`echo $h|awk -F '/' '{print $1}'|awk -F '-' '{print $2}'|sort -u`
	cp -f $h /arthas/sites/$webent/ROOT$filepath
	echo $h copy finied!
    fi
    let i++
done
