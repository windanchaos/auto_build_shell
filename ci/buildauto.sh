#!/bin/sh
#auto build when the code update in 1 hour
#created by bojiang@maike51.com
source /etc/profile
webents=(mk-aggregator mk-smart-webent mk-demon-webent mk-wm-msger mk-app-webent mk-job-webent mk-openApi mk-wm-webent mk-yum-webent mk-imgr-webent mk-uic-webent mk-qdragon-webent mk-sn-webent mk-intf-webent mk-kunlun-webent mk-imgr-rpc mk-yum-rpc mk-mdata-rpc mk-uic-rpc mk-sn-rpc)
echo "执行时间"`date`
cd ~/ArhasMK
history=`git log --since=9.hours -p . |grep diff |awk '{print $4}' |awk -F 'b/' '{print $2}'|sort -u|awk -F '/' '{print $1}'|sort -u`
arr=(`echo $history`) 
#get webent list first ,then build service before webents
buildwebent=()
#get webents in history
for h in ${arr[@]}
do
    for webent in ${webents[@]} 
    do
	if [ "$h" == "$webent"  ] ;then
 	 buildwebent[${#buildwebent[@]}]=$h
	fi
    done
done
#get service,by remove webent from history
service=()
i=0
#Dynamic arr,longth needs get first
longth=${#arr[@]}
while [ $i -lt $longth ]
do
    for b in ${buildwebent[@]}
    do
	if [ "${arr[$i]}" == "$b"  ] ;then
	   unset arr[$i]
        fi
    done
    let i++
done
#service build first
for s in ${arr[@]}
do
    if [ "$s" != "mk-dbscript-mysql" ] && [ "$s" != "fontend-vue" ] && [ "$s" != "mk-static" ] ;then
        echo "build service $s"
        cd $h && mvn -q -ff clean install
        cd ..
    fi
#service deploy to tomcat
    RPM=1
    longthpub=`expr $longth - 5`
    while [ $RPM -lt $longthpub ]
    do
        #执行代码更新操作
	if [ -f "~/ArhasMK/$s/target/$s.jar" ] ;then 
        echo "$ 更新---------------------"
	 siteName=`echo ${s#*-}`
        cp -f "~/ArhasMK/$s/target/$s.jar"  "/arthas/sites/${siteName}/ROOT/WEB-INF/lib" && echo "$s覆盖完成！"
        fi
        let RPM++
    done
done

#webent build last
for b in ${buildwebent[@]}
do
    echo "build webent $b"
    cd $b && mvn -q -ff clean install -P st-https
    cd ..
done

#vue if need 
for s in ${arr[@]}
do
    if [ "$s" == "fontend-vue" ]  ;then
       bash ~/ci/vue.sh
    fi
done

