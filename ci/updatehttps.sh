#!/bin/bash
githome="/home/admin/ArhasMK/"
sitesPath="/arthas/sites/"
DATE=$(date +%Y%m%d%H%M)
softfile="/home/admin/ArhasMK/"
sitesbackup="/home/admin/sitesbackup/"
git_FE="/home/admin/ArthasMK_FE"
git_MK="/home/admin/ArhasMK/mk-smart-webent/src/main/webapp/WEB-INF/views/"

#设置环境变量
source /etc/profile
webents=(mk-aggregator mk-smart-webent mk-demon-webent mk-kunlun-webent mk-wm-msger mk-app-webent mk-job-webent mk-openApi mk-wm-webent mk-yum-webent mk-imgr-webent mk-uic-webent mk-qdragon-webent mk-sn-webent mk-intf-webent mk-imgr-rpc mk-yum-rpc mk-mdata-rpc mk-uic-rpc mk-sn-rpc mk-msg-mid)
longth=${#webents[@]}
RPM=0
#git拉取代码
echo "请确认使用该命令，已经从git库拉取了最新的代码，使用了正确的分支"
cd ${githome}
#echo "git分支名称："+`git branch |awk '{print $4}'|head -3`
git checkout .
git reset --hard HEAD^
echo "git分支名称："+`git status |awk '{print $3}' |head -1`
echo "拉取当前分支代码"
#git pull origin `git status |awk '{print $4}'|head -1|awk -F 'in/' '{print $2}'`
git pull origin `git status |awk '{print $3}'|head -1` && 
echo "编译工程，静默方式，过程如果报错会提示，提示需检查错误后重新编译！"

while [ $RPM -lt $longth ]  && [ $? -eq 0  ]
do
	cd ${githome}${webents[$RPM]} && echo "编译${webents[$RPM]}"
	mvn -q -ff clean install -P st2 && echo "${webents[$RPM]}编译完成！"
	let RPM++
done

echo "数组长度：$longth"
#更新rpc
longthpub=`expr $longth - 6`
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
                nohup  java -Xms246m -Xmx500m -jar ${webents[$RPM]}.jar > ${webents[$RPM]}".log" &
        	rm -fr $softfile${webents[$RPM]}/target
	fi
        let RPM++
done

#更新webent
RPM=1
longthpub=`expr $longth - 6`
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
		rm -fr $softfile${webents[$RPM]}/target
        fi
        let RPM++
done
#结束tomcat进程
kill -9 ${k}`ps -fe |grep tomcat |awk '{print $2}'|head -3`
#替换server.xml配置
#cd /arthas/servers/apache-tomcat-8.5.4-80/conf/
#cp -f server-https.xml server.xml
#开启tomcat
#cd /arthas/servers/apache-tomcat-8.5.4-80/bin
#./startup.sh

cd /arthas/servers/apache-tomcat-8.5.4-80/bin/
./startup.sh

#echo "VUE编译中！！！！！"
#bash ~/vue.sh
#echo "VUE编译完"

#VUE push
#cd /home/admin/ArhasMK
#git add -A
#git commit -a -m "auto update vue"
#git pull 
#git push http://carrier.maike51.com:81/alm/MK/_git/ArhasMK origin/"`git status |awk '{print $4}' |head -1`":"`git status |awk '{print $4}' |head -1`"

#静态资源
#tar -zcf /home/admin/ArhasMK/mk-static/WebContent/resources.tar.gz -C /home/admin/ArhasMK/mk-static/WebContent resources
#sftp admin@172.16.0.5 <<EOE
#put /home/admin/ArhasMK/mk-static/WebContent/resources.tar.gz /mk/sites/crs
#EOE
#ssh -tt admin@172.16.0.5 << EOF
#cd /mk/sites/crs
#rm -fr resources
#tar -zxf resources.tar.gz
#exit
#EOF
#echo "===============静态资源发布完毕========="


