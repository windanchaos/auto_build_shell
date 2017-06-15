#!/bin/bash
githome="/home/mkstar/ArhasMK/"
sitesPath="/arthas/sites/"
git_MK="/home/mkstar/ArhasMK/mk-smart-webent/src/main/webapp/WEB-INF/views/"
echo "执行时间:"`date`
#设置环境变量
source /etc/profile
webents=(mk-aggregator mk-smart-webent mk-demon-webent mk-wm-msger mk-app-webent mk-job-webent mk-openApi mk-wm-webent mk-yum-webent mk-imgr-webent mk-uic-webent mk-qdragon-webent mk-sn-webent mk-intf-webent mk-kunlun-webent mk-imgr-rpc mk-yum-rpc mk-mdata-rpc mk-uic-rpc mk-sn-rpc)
#更新rpc
longth=${#webents[@]}
longthpub=`expr $longth - 5`
echo "数组长度：$longth"

if [ -f $githome"${webents[$1]}/target/${webents[$1]}.jar" ] && [  $1 -ge $longthpub ]; then
	webentname=`echo ${webents[$1]}`
	siteName=`echo ${webentname#*-}`
	#判断是否存在webent，不存在则新建
	if [ ! -d  $sitesPath${siteName}  ]; then
		echo "新建路径：${sitesPath}${siteName}"
		mkdir -p $sitesPath${siteName}
	fi
	#执行代码更新操作
	echo "$siteName更新---------------------"
	kill -9 ${k}`ps -fe |grep $siteName |awk '{print $2}'|head -2`
	cd $sitesPath${siteName} && rm -fr `ls $sitesPath${siteName}` && echo "删除完成！"
	cp -r $githome"${webents[$1]}/target/lib" $githome"${webents[$1]}/target/${webents[$1]}.jar"  $sitesPath${siteName} && echo "$siteName解压完成！"
	nohup  java -Xms246m -Xmx500m -jar ${webents[$1]}.jar > ${webents[$1]}".log" &
fi


#更新webent
if [ -f $githome"${webents[$1]}/target/${webents[$1]}.war" ] && [ $1 -lt $longthpub ] && [ $1 -gt 0 ]; then
	siteName=`echo ${webents[$1]}|awk -F '-' '{print $2}'`
	#判断是否存在webent，不存在则新建
	if [ ! -d  "$sitesPath${siteName}/ROOT"  ]; then
		echo "新建路径：${sitesPath}${siteName}/ROOT"
		mkdir -p "${sitesPath}${siteName}/ROOT"
	fi
	
	#执行代码更新操作
	echo "$siteName 更新---------------------"
	cd ${sitesPath}${siteName}"/ROOT" && rm -fr `ls -I shopInfo` && echo "删除完成！"
	unzip -q $githome"${webents[$1]}/target/${webents[$1]}.war" -d $sitesPath${siteName}"/ROOT" && echo "$siteName解压完成！"
fi
