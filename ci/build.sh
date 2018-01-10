#!/bin/bash
#设置环境变量
source /etc/profile
##代码编写遵守<Defensive BASH Programming>博客描述的以下原则
########	Immutable global variables 
########	Everything is local
########	Everything is a function
########	Debugging functions(bash -x)(set -x  …… set +x)
########	Code clarity
########	Each line does just one thing


#本地git代码库
myname=`whoami`
mypath=`cat /etc/passwd | grep $myname | awk -F ":" '{print $6}'|head -1`
GIT_HOME="${mypath}/ArhasMK/"
#部署路径
readonly SITE_PATH="/arthas/sites"
#git编译的参数
readonly PROFILE="st-https"

#远程服务器链接信息，需设置ssh免密登陆
readonly CONFIG_REMOTE_IP="121.43.164.242"
readonly CONFIG_REMOTE_USER="mkstar"
readonly CONFIG_REMOTE_PORT="22"

#远程服务器tomcat路径
readonly REMOTE_TOMCAT="/arthas/servers01/apache-tomcat-8.5.4-80/"

echo "执行时间:"`date`

#部署到tomcat的项目
webents=(mk-smart-webent mk-demon-webent mk-app-webent mk-job-webent mk-openApi mk-wm-webent mk-yum-webent mk-imgr-webent mk-uic-webent mk-qdragon-webent mk-sn-webent mk-intf-webent mk-kunlun-webent)
#单独部署的rpc服务
webents_RPC=(mk-imgr-rpc mk-yum-rpc mk-mdata-rpc mk-uic-rpc mk-sn-rpc mk-wm-msger)




##############################################################################
###       更新代码库
##############################################################################

function pull_code(){
	cd ${GIT_HOME}
	echo "git分支名称：" 　\
	`git status |awk '{print $4}' |head -1`
	echo "拉取当前分支代码"
	git pull origin \
	`git status |awk '{print $4}'|head -1` 
}
function build_agg(){
        cd ${GIT_HOME}/mk-aggregator && echo "building mk-aggregator"
        mvn -q -ff clean install
}

##############################################################################
###       构建项目函数，传入webent名称
##############################################################################
function build(){
	local webent=$1;
	cd ${GIT_HOME}/$webent && echo "building $webent"
	mvn -q -ff clean install -P $PROFILE
	if [ -e target/ROOT.war ] || [ -e target/${webent}.jar ] ;then
		echo "$webent build finished! "
	else	
		echo "$webent build ERROR,Please check your code!"
	fi
	if [ -e target/${webent}.jar ] ;then
		cd target
		tar -zcf ${webent}.tar.gz lib ${webent}.jar
	fi
}


##############################################################################
###       部署到tomcat的函数，传入webent名称
##############################################################################
function deploy_webent(){
	cd ${GIT_HOME}
	webent=${1}
	echo "${1}"
	webent_name="`echo ${1}|awk -F '-' '{print $2}'`"
	echo $webent_name
if [ -e ${webent}/target/ROOT.war ] ;then
ssh -tt ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} -p ${CONFIG_REMOTE_PORT} << EOE
if [ ! -e "${SITE_PATH}/${webent_name}" ];then
mkdir -p ${SITE_PATH}/${webent_name}
rm -fr ${SITE_PATH}/${webent_name}/ROOT*
fi
exit
EOE
sftp -P ${CONFIG_REMOTE_PORT} ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} << EOE
put ${webent}/target/ROOT.war ${SITE_PATH}/${webent_name}	
EOE
fi
}


##############################################################################
###       部署RPC的函数，传入RPC名称
##############################################################################
function deploy_RPC(){
	cd ${GIT_HOME}
	webent=${1}
	webent_name="${1#*-}"
	if [ -e ${webent}/target/${webent}.jar ] ;then
ssh -tt ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} -p ${CONFIG_REMOTE_PORT} << EOE
if [ ! -e "${SITE_PATH}/${webent_name}" ];then
mkdir -p ${SITE_PATH}/${webent_name}
rm -fr ${SITE_PATH}/${webent_name}/*
fi
exit
EOE

sftp -P ${CONFIG_REMOTE_PORT} ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} << EOE
put ${webent}/target/$webent.tar.gz ${SITE_PATH}/${webent_name}
exit	
EOE
		
ssh -tt ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} -p ${CONFIG_REMOTE_PORT} << EOD
kill -9 ${k}`ps -fe |grep -v grep|grep $webent_name |awk '{print $2}'|head -1`
cd ${SITE_PATH}/${webent_name}/
tar -zxf ${webent}.tar.gz &&
nohup java -Xms246m -Xmx500m -jar ${webent}.jar > ${webent}.log &
exit
EOD
fi	
}

##############################################################################
###       重启远程tomcat
##############################################################################
function restartom(){
	ssh -tt ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} -p ${CONFIG_REMOTE_PORT}<<EOF
kill -9 ${k}`ps -fe |grep -v grep | grep ${REMOTE_TOMCAT} |awk '{print $2}'|head -1`
cd ${REMOTE_TOMCAT}/bin && ./startup.sh
exit
EOF
}


pull_code
#build_agg
#for webent in ${webents[@]} ;do
#        build ${webent} 
#done
for webent in ${webents_RPC[@]} ;do
        build ${webent}
done
#for webent in ${webents[@]} ;do
#      deploy_webent ${webent}
#done
echo "hai"
for webent in ${webents_RPC[@]} ;do
       echo "${webent}"
	deploy_RPC ${webent}
done
#deploy_webent mk-wm-webent

