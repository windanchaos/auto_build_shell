#!/bin/bash
githome="~/ArhasMK/"
sitesPath="/arthas/sites/"
profiles="st-https"


#设置环境变量
source /etc/profile

echo "执行时间:"`date`

webents=(mk-aggregator mk-smart-webent mk-demon-webent mk-wm-msger mk-app-webent mk-job-webent mk-openApi mk-wm-webent mk-yum-webent mk-imgr-webent mk-uic-webent mk-qdragon-webent mk-sn-webent mk-intf-webent mk-kunlun-webent)
webent_RPC=(mk-imgr-rpc mk-yum-rpc mk-mdata-rpc mk-uic-rpc mk-sn-rpc)




##############################################################################
###       更新代码库
##############################################################################

function pull_code(){
	cd ${githome}
	echo "git分支名称："+`git status |awk '{print $4}' |head -1`
	echo "拉取当前分支代码"
	git pull origin `git status |awk '{print $4}'|head -1` 
}
##############################################################################
###       构建项目函数，传入webent名称
##############################################################################
function build(){
	cd ${githome}/$1 && echo "building $1"
	mvn -q -ff clean install -P $profile
	if [ -e $1/target/ROOT.war ] || [ -e $1/target/$1.jar ] ;then
		echo "$1 build finished! "
	else	
		echo "$1 build ERROR,Please check your code!"
}

