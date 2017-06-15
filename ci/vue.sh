#!/bin/bash
githome="/home/mkstar/ArhasMK/"
sitesPath="/arthas/sites/"
DATE=$(date +%Y%m%d%H%M)
sitesbackup="/home/mkstar/sitesbackup/"
git_FE="/home/mkstar/ArthasMK_FE"
#git_MK="/home/mkstar/ArhasMK/mk-smart-webent/src/main/webapp/WEB-INF/views/"
git_MK="/arthas/sites/smart/ROOT/WEB-INF/views/"
#设置环境变量
source /etc/profile
cd $githome
git pull origin `git status |awk '{print $4}'|head -1`
#VUE
cd $githome"fontend-vue"
#npm install -g cnpm --registry=https://registry.npm.taobao.org
#cnpm install
npm run build

rm -fr /arthas/sites/smart/ROOT/resources/smart-static/*
cp -fr /home/mkstar/ArhasMK/fontend-vue/dist/smart-static/* /arthas/sites/smart/ROOT/resources/smart-static/
target=()
cd dist
RPM=0
cd /arthas/sites/smart/ROOT/resources/smart-static/css/
source[0]="`ls app.* |awk -F '.' '{print $2 }'`"
cd ../js
source[1]="`ls manifest.*|awk -F '.' '{print $2 }'`"
source[2]="`ls vendor.*|awk -F '.' '{print $2 }'`"
source[3]="`ls app.*|awk -F '.' '{print $2 }'`"
target[0]="`grep smart-static $git_MK"index.jsp" |awk -F '.' 'NR==1 {print $2}'`"
target[1]="`grep smart-static $git_MK"index.jsp" |awk -F '.' 'NR==2 {print $2}'`"
target[2]="`grep smart-static $git_MK"index.jsp" |awk -F '.' 'NR==3 {print $2}'`"
target[3]="`grep smart-static $git_MK"index.jsp" |awk -F '.' 'NR==4 {print $2}'`"


#echo ${#source[@]}
#echo ${#target[@]}
echo ${target[@]}
echo ${source[@]}

while [ $RPM -lt 4 ]
do
        echo ${target[$RPM]}/${source[$RPM]}
        sed -i "s/${target[$RPM]}/${source[$RPM]}/g" $git_MK"index.jsp"
        let RPM++
done



