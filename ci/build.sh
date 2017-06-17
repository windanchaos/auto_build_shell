#!/bin/bash
##代码编写遵守<Defensive BASH Programming>博客描述的以下原则
########	Immutable global variables 
########	Everything is local
########	Everything is a function
########	Debugging functions(bash -x)(set -x  …… set +x)
########	Code clarity
########	Each line does just one thing


#本地git代码库
readonly GIT_HOME="~/ArhasMK/"
#部署路径
readonly SITE_PATH="/arthas/sites/"
#git编译的参数
readonly PROFILES="st-https"

#远程服务器链接信息，需设置ssh免密登陆
readonly CONFIG_REMOTE_IP="121.43.164.242"
readonly CONFIG_REMOTE_USER="mkstar"
readonly CONFIG_REMOTE_PORT="22"

#远程服务器tomcat路径
readonly REMOTE_TOMCAT="/arthas/servers01/apache-tomcat-8.5.4-80/"
#设置环境变量
source /etc/profile

echo "执行时间:"`date`

#部署到tomcat的项目
webents=(mk-aggregator mk-smart-webent mk-demon-webent mk-wm-msger mk-app-webent mk-job-webent mk-openApi mk-wm-webent mk-yum-webent mk-imgr-webent mk-uic-webent mk-qdragon-webent mk-sn-webent mk-intf-webent mk-kunlun-webent)
#单独部署的rpc服务
webents_RPC=(mk-imgr-rpc mk-yum-rpc mk-mdata-rpc mk-uic-rpc mk-sn-rpc)




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


##############################################################################
###       构建项目函数，传入webent名称
##############################################################################
function build(){
	local webent=$1; shift
	cd ${GIT_HOME}/$webent && echo "building $webent"
	mvn -q -ff clean install -P $profile
	if [ -e $webent/target/ROOT.war ] || [ -e $webent/target/$webent.jar ] ;then
		echo "$webent build finished! "
	else	
		echo "$webent build ERROR,Please check your code!"
	
	if [ -e $webent/target/$webent.jar ] ;then
		cd $webent/target
		tar -zcv $webent.tar.gz lib　$webent.jar
}


##############################################################################
###       部署到tomcat的函数，传入webent名称
##############################################################################
function deploy_webent(){
	cd ${GIT_HOME}
	local　webent=$1
	local　webent_name="$1|awk -F '-' '{print $2}'"
	if [ -e $webent/target/ROOT.war ] ;then
		ssh -tt ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} -p ${CONFIG_REMOTE_PORT}<<EOF
			if [ ! -e ${SITE_PATH}/${webent_name} ];then
				mkdir -p ${SITE_PATH}/${webent_name}
			rm ${SITE_PATH}/${webent_name}/ROOT*
			exit
		EOF
		
		sftp ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} -P ${CONFIG_REMOTE_PORT}<<EOE
			put $webent/target/ROOT.war ${SITE_PATH}/${webent_name}	
		EOE
}


##############################################################################
###       部署RPC的函数，传入RPC名称
##############################################################################
function deploy_RPC(){
	cd ${GIT_HOME}
	local　webent=$1
	local webent_name="${1#*-}"
	if [ -e $webent/target/ROOT.war ] ;then
		ssh -tt ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} -p ${CONFIG_REMOTE_PORT}<<EOF
			if [ ! -e ${SITE_PATH}/${webent_name} ];then
				mkdir -p ${SITE_PATH}/${webent_name}
			rm ${SITE_PATH}/${webent_name}/*
			exit
		EOF

		sftp ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} -P ${CONFIG_REMOTE_PORT}<<EOE
			put $webent/target/$webent.tar.gz ${SITE_PATH}/${webent_name}
			exit	
		EOE
		
		ssh -tt ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} -p ${CONFIG_REMOTE_PORT}<<EOD
			kill -9 ${k}`ps -fe |grep $webent_name |awk '{print $2}'|head -1`
			tar -zxf $webent.tar.gz &&
			nohup java -Xms246m -Xmx500m -jar $webent.jar > $webent.log &
			exit
		EOD
		
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

##############################################################################
###       多线程控制和执行，fifofile()在循环外执行，循环内执行multi_line()函数带语句
###	  作为参数
##############################################################################
function fifofile(){
	# 新建一个fifo类型的文件 
	tmp_fifofile="/tmp/$$.fifo"
	mkfifo $tmp_fifofile 
	#将fd6指向fifo类型
	exec 6 <> $tmp_fifofile 
	rm $tmp_fifofile
	# 此处定义线程数
	thread = 4 
	for ((i=0;i<$thread;i++)); do
	echo
	#事实上就是在fd6中放置了$thread个回车符
	done >& 6 
	# 一个read -u6命令执行一次，就从fd6中减去一个回车符，然后向下执行
}

function multi_line(){
	# 循环执行１次减去一个回车符，减到０，就是实现线程数量控制
	read -u6
	{
	#要执行的命令，命令使用双引号分开		
		for i in %@
		do
			$i	
		done
	#当进程结束以后，再向fd6中加上一个回车符，即补上了read -u6减去的那个
	    echo >& 6 
	} &

	# 等待所有后台子进程结束
	wait
	#关闭fd6
	exec 6>&- 
	exit 0
}

