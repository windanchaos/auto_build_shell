#!/bin/bash
githome="/home/mkstar/ArhasMK/"
sitesPath="/arthas/sites/"
DATE=$(date +%Y%m%d%H%M)
softfile="/home/mkstar/ArhasMK/"
sitesbackup="/home/mkstar/sitesbackup/"
git_FE="/home/mkstar/ArthasMK_FE"
git_MK="/home/mkstar/ArhasMK/mk-smart-webent/src/main/webapp/WEB-INF/views/"

echo "执行时间"`date`
#设置环境变量
source /etc/profile
webents=(mk-aggregator mk-smart-webent mk-demon-webent mk-wm-msger mk-app-webent mk-job-webent mk-openApi mk-wm-webent mk-yum-webent mk-imgr-webent mk-uic-webent mk-qdragon-webent mk-sn-webent mk-intf-webent mk-kunlun-webent mk-imgr-rpc mk-yum-rpc mk-mdata-rpc mk-uic-rpc mk-sn-rpc)
longth=${#webents[@]}
RPM=0

#更新rpc
longthpub=`expr $longth - 5`
RPM=$longthpub
while [ $RPM -lt $longth ]  && [ $? -eq 0  ]
do
        if [ -f $softfile"${webents[$RPM]}/target/${webents[$RPM]}.jar" ]; then
                webentname=`echo ${webents[$RPM]}`
                siteName=`echo ${webentname#*-}`
        #判断是否存在webent，不存在则新建
                if [ ! -d  $sitesPath${siteName}  ]; then
        	        echo "新建路径：${sitesPath}${siteName}"
			mkdir -p $sitesPath${siteName}
                        #echo ${webents[$RPM]}|awk -F '-' '{print $2}'
                fi
                #执行代码更新操作
                echo "$siteName更新---------------------"
                kill -9 ${k}`ps -fe |grep $siteName |awk '{print $2}'|head -2`
                cd $sitesPath${siteName} && rm -fr `ls $sitesPath${siteName}` && echo "删除完成！"
                cp -r $softfile"${webents[$RPM]}/target/lib" $softfile"${webents[$RPM]}/target/${webents[$RPM]}.jar"  $sitesPath${siteName} && echo "$siteName解压完成！"
                nohup  java -Xms246m -Xmx500m -jar ${webents[$RPM]}.jar &
        	rm -fr $softfile"${webents[$RPM]}/target"
	fi
        let RPM++
done

#更新webent
RPM=1
longthpub=`expr $longth - 5`
while [ $RPM -lt $longthpub ]
do
        if [ -f $softfile"${webents[$RPM]}/target/${webents[$RPM]}.war" ]; then
                siteName=`echo ${webents[$RPM]}|awk -F '-' '{print $2}'`
		#判断是否存在webent，不存在则新建
                if [ ! -d  "$sitesPath${siteName}/ROOT"  ]; then
			echo "新建路径：${sitesPath}${siteName}/ROOT"
                        mkdir -p "${sitesPath}${siteName}/ROOT"
			#echo ${webents[$RPM]}|awk -F '-' '{print $2}'
                fi
		#执行代码更新操作
		echo "$siteName 更新---------------------"
		cd ${sitesPath}${siteName}"/ROOT" && rm -fr `ls -I shopInfo` && echo "删除完成！"
		unzip -q $softfile"${webents[$RPM]}/target/${webents[$RPM]}.war" -d $sitesPath${siteName}"/ROOT" && echo "$siteName解压完成！"
		rm -fr $softfile"${webents[$RPM]}/target"
        fi
        let RPM++
done
#结束tomcat进程
#kill -9 ${k}`ps -fe |grep tomcat |awk '{print $2}'|head -3`
#开启tomcat
#cd /arthas/servers01/apache-tomcat-8.5.4-80/bin/
#./startup.sh

#echo "VUE编译中！！！！！"
#bash ~/vue.sh
#echo "VUE编译完"
