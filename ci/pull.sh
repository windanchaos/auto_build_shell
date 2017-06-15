#!/bin/bash
githome="/home/mkstar/ArhasMK/"
#设置环境变量
source /etc/profile
echo "执行时间"`date`
cd ${githome}
#git reset --hard HEAD^
echo "git分支名称："+`git status |awk '{print $4}' |head -1`
echo "拉取当前分支代码"
git pull origin `git status |awk '{print $4}'|head -1` 

