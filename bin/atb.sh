#!/bin/bash
##############################################################################
###             没有任何修饰符参数 : 原生参数
###             <>  : 占位参数 
###             []  : 可选组合
###             ()  : 必选组合
###             |   : 互斥参数
###             ... : 可重复指定前一个参数
###             --  : 标记后续参数类型
##############################################################################

##############################################################################
###    打印 banner
##############################################################################
function show_banner(){
    echo "##################################################################################################"
    echo "#                                                                                                #"
    echo "#   █████╗ ████████╗██████╗     ██████╗ ██╗   ██╗         ██╗██╗███╗   ██╗██╗  ██╗██╗███╗   ██╗  #"
    echo "#  ██╔══██╗╚══██╔══╝██╔══██╗    ██╔══██╗╚██╗ ██╔╝         ██║██║████╗  ██║╚██╗██╔╝██║████╗  ██║  #"
    echo "#  ███████║   ██║   ██████╔╝    ██████╔╝ ╚████╔╝          ██║██║██╔██╗ ██║ ╚███╔╝ ██║██╔██╗ ██║  #"
    echo "#  ██╔══██║   ██║   ██╔══██╗    ██╔══██╗  ╚██╔╝      ██   ██║██║██║╚██╗██║ ██╔██╗ ██║██║╚██╗██║  #"
    echo "#  ██║  ██║   ██║   ██████╔╝    ██████╔╝   ██║       ╚█████╔╝██║██║ ╚████║██╔╝ ██╗██║██║ ╚████║  #"
    echo "#  ╚═╝  ╚═╝   ╚═╝   ╚═════╝     ╚═════╝    ╚═╝        ╚════╝ ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝  #"
    echo "#                                                                                                #"
    echo "##################################################################################################"
}

##############################################################################
###    显示帮助
##############################################################################
function show_help(){
    echo
    echo "usage: atb [Options]"
    echo
    echo "Options："
    echo " -v                                    版本号与项目信息"
    echo " -i                                    根据配置文件进行初始化"
    echo " -c                                    clean 工程"
    echo " -du  [ -l ]                           跳过编译步骤直接上传已存在war包到本地服务器"
    echo " -du -r <server_flag>                  跳过编译步骤直接上传已存在war包到指定的远程服务器"
    echo " -h                                    帮助"
    echo " -l                                    自动编译打包本地部署"
    echo " -r <server_flag>                      自动编译打包远程部署到指定的远程服务器"
    echo " -r <server_flag> -his                 查看指定的远程服务器上备份历史"
    echo " -r <server_flag> -rb <backup_version> 将指定服务器web应用回滚到指定版本"
}

##############################################################################
###    读取配置文件 [配置文件路径+名称] [节点名] [键值]
##############################################################################
function read_ini() {
    ini_file=$1;
    section=$2;
    key=$3
    # 读取配置文件，排除'#'开头的行，将结果作为awk的输入
    # 以'='做分隔符,找到节点下面的匹配key的行，按'='分割为$1 $2 $2即所需要的值，如果$2为逗号分开的数组 则转换为shell数组
    sed -e s/^#.*//g $ini_file | awk -F '=' '/^[^#]/{}/\['$section'\]/{a=1}a==1&&$1~/'$key'/{ for (i=1; i<= split($2,array,","); i++) print array[i]" "}'
    # awk -F '=' '/\['$section'\]/{a=1}a==1&&$1~/'$key'/{ print $2 }' $ini_file
}

##############################################################################
###       初始化
##############################################################################
function init(){
    show_banner
    echo "atb 初始化中..."
    echo "正在检查本地发版路径..."
    check_path_and_create ${local_project_basepath}
    echo "正在检查远程发版路径..."
    check_path_and_create ${remote_project_basepath}
    echo "正在检查代码管理工具..."
    echo "检测到当前配置代码管理工具为 [ ${checkout_command[0]} ]" 
    case "${checkout_command[0]}" in
        svn )
            init_checkout_command=(svn checkout)
            init_checkout_code ${local_project_basepath} "${init_checkout_command[*]}"
            init_checkout_code ${remote_project_basepath} "${init_checkout_command[*]}"
            ;;
        git )
            init_checkout_command=(git clone)
            init_checkout_code ${local_project_basepath} "${init_checkout_command[*]}"
            init_checkout_code ${remote_project_basepath} "${init_checkout_command[*]}"
            ;;
    esac
    # echo "正在检查构建工具..."
    # case "${checkout_command[0]}" in
    #     mvn )
    #         echo "检测到当前配置代码管理工具为 [ ${checkout_command[0]} ]" 
            
    #         ;;
    #     git )
    #         echo "检测到当前配置代码管理工具为 [ ${checkout_command[0]} ]" 
                
    #         ;;
    # esac
    for i in "${!remote_ips[@]}"; do  
        # 初始化时的command_ssh
        command_ssh=(ssh -t -T -p ${remote_ports[$i]} ${remote_users[$i]}@${remote_ips[i]})
        echo "正在检查${remote_ips[$i]} 上 [ ${remote_shell_dir} ] 是否存在..."
        check_remote_path_and_create $i
        upload_restart_file ${remote_shell_name} $i
    done
    
    exit 0
}

##############################################################################
###       本地及远程路径检查 不存在则创建
##############################################################################
function check_path_and_create(){
    if [[ ! -e "$1" ]]; then
        echo "开始创建文件夹 [ $1 ] "
        mkdir -p $1
        return 0
    fi
    echo "[ $1 ] 已存在"
    return 0
}

##############################################################################
###       若脚本不存在上传restart脚本 接收参数: 远程配置数组索引$1
##############################################################################
function check_remote_path_and_create(){
    if ! ssh ${remote_users[$1]}@${remote_ips[$1]} test -d ${remote_shell_dir}; then
        echo "开始创建文件夹 [ ${remote_shell_dir} ] "
        # echo ${command_ssh[@]} "mkdir -p ${remote_shell_dir}"
        ${command_ssh[@]} "mkdir -p ${remote_shell_dir}"
        return 0
    fi
    echo "${remote_users[$1]}@${remote_ips[$1]} 上 [ ${remote_shell_dir} ] 已存在"
    return 0
}

##############################################################################
###       检查是否已经初始化过，若未初始化则检出代码（异步执行）
##############################################################################
function init_checkout_code(){
    # echo $2
    #文件夹判空
    count=`ls $1|wc -w`
    if [[ "$count" -eq "0" ]]; then
        echo "开始从资源库 [ ${repository_url} ] 检出代码" 
		case "${checkout_command[0]}" in
			svn )
				cd $1 && $2 ${repository_url} --username ${svn_username} --password ${svn_password}
				;;
			git )
				cd $1 && $2 ${repository_url} && exit 0 &
				;;
		esac
        
    fi
    echo "[ $1 ] 代码已检出"
    return 0
}

##############################################################################
###       若脚本不存在上传restart脚本 接收参数: 文件名: $1, 远程配置数组索引 $2
##############################################################################
function upload_restart_file(){
    if ! ssh ${remote_users[$2]}@${remote_ips[$2]} test -e "${remote_shell_dir}/$1"; then
         echo "ip: [ ${remote_ips[$2]} ] restart.sh文件上传中..."
         scp ${ATB_HOME}/bin/$1 "${remote_users[$2]}@${remote_ips[$2]}:${remote_shell_dir}"
        return 0
    fi
    echo "${remote_users[$2]}@${remote_ips[$2]} [ ${remote_shell_dir}/$1 ] 已存在"
    return 0
}

##############################################################################
###       查看发布历史
##############################################################################
function show_deploy_history(){
    echo "↓                                         备份列表                                               ↓"
    # echo ${command_ssh[@]} "cd ${remote_backup_path} && ls -lhG"
    ${command_ssh[@]} "cd ${remote_backup_path} && ls -lhG"
    return 0
}

##############################################################################
###       检出代码
##############################################################################
function checkout_code(){
    echo "正在从资源库 [ $repository_url ] 检出代码"
    #字符串转命令通用写法
    eval ${checkout_command[@]}
    return 0
}

##############################################################################
###       maven clean
##############################################################################
function clear_project(){
    echo "${maven_shell} clean"
    ${maven_shell} clean
    return 0
}

##############################################################################
###       编译打包
##############################################################################
function package(){
    if [[ "${profile}" = "" ]]; then
        echo "mvn clean package -DskipTests=true"
        ${maven_shell} clean package -DskipTests=true
        return 0
    fi
    echo "mvn clean package -DskipTests=true -P$profile"
    ${maven_shell} clean package -DskipTests=true -P${profile}
    return 0
}

##############################################################################
###    检查war是否已存在，不存在退出 返回值 0-存在，1-不存在
##############################################################################
function check_war(){
    if [ -e "$war_path" ]; then
        return 0
    fi
    echo "$war_path 下面 war包不存在"
    return 1
}

##############################################################################
###    本地拷贝
##############################################################################
function local_copy(){
    # echo "进入war包目录：$sub_project_path/target"
    # echo "开始传输war包到本地服务器目录：$server_path/webapps"
    cd "$sub_project_path/target"
    cp $war_name "$server_path/webapps/$war_name"
}

##############################################################################
###       远程拷贝 先拷贝到备份文件夹，然后关闭tomcat，从备份文件中拷贝出最新版 重启tomcat
##############################################################################
function remote_copy(){
    # echo "Param: remote_user = $remote_user" 
    # echo "Param: remote_ip = $remote_ip" 
    # echo "Param: remote_port = $remote_port" 
    # echo "Param: remote_pwd = $remote_pwd" 
    echo "进入war包目录：${sub_project_path}/target"
    cd "${sub_project_path}/target"
    
    #检查服务器上备份文件夹是否存在
    if ssh ${remote_user}@${remote_ip} test -d ${remote_backup_path}; then
        echo "[ ${remote_backup_path} ]已存在"
    else 
        echo "[ ${remote_backup_path} ]创建中"
        ${command_ssh[@]} "mkdir -p ${remote_backup_path}"
        echo "[ ${remote_backup_path} ]创建成功"
    fi

    #定义远程文件名称
    remote_war_name=""
    if [[ ${remote_backup_switch} == "on" ]]; then
        # 查看备份文件个数
        backup_file_num=$(${command_ssh[@]} "cd ${remote_backup_path} && ls -l | grep "^-" | wc -l")
        if [[ "${backup_file_num}" -ge "${remote_max_backup_file_num}" ]]; then
            echo "备份数[ ${backup_file_num} ]超过最大备份数量"
            echo "删除早期备份文件$(${command_ssh[@]} "cd ${remote_backup_path} && ls -rt|head -1")"
            # 删除最早备份文件
            ${command_ssh[@]} "cd ${remote_backup_path} && ls -rt|head -1|xargs rm -rf" 
        fi
        # 按日期备份
        current_time=`date +%Y%m%d%H%M%S`
        remote_war_name=${war_name%.*}_${current_time}
    else
        remote_war_name=${war_name}
    fi
    
    #打印密码方便拷贝
    echo "开始传输 [ ${war_name} ] 到 ${remote_user}@${remote_ip}:${remote_backup_path}/${remote_war_name} 密码：${remote_pwd}"
    scp ${war_name} "${remote_user}@${remote_ip}:${remote_backup_path}/${remote_war_name}"
}

##############################################################################
###       重启远程服务器
##############################################################################
function restart_remote_server() {
    # echo "${command_ssh[@]} $remote_shell_dir/restart.sh ${war_name} ${remote_server_path}"
    # 执行服务器重启脚本
    # -T     Disable pseudo-terminal allocation.
    # -t     Force pseudo-terminal allocation.  T
    #         his can be used to execute arbitrary screen-based programs on a remote machine, 
    #         which can be very useful, e.g.
    #       when implementing menu services.  
    #       Multiple -t options force tty allocation, even if ssh has no local tty.
    # -p 指定端口号
    echo "重启服务中..."
    ${command_ssh[@]} "$remote_shell_dir/$remote_shell_name ${war_name} ${remote_server_path}"
}

##############################################################################
###       回滚到某个版本
##############################################################################
function rollback_backup_version() {
    echo "回滚中..."
    ${command_ssh[@]} "$remote_shell_dir/$remote_shell_name ${backup_version} ${remote_server_path}"
}

##############################################################################
###       重启本地服务器
##############################################################################
function restart_local_server() {
    cd "$server_path"
    # ./bin/shutdown.sh
    # 根据程唯一筛选条件杀死进程
    ps -ef | grep ${server_path##*/} | grep -v grep | awk '{print $2}'  | sed -e "s/^/kill -9 /g" | sh -
    ./bin/startup.sh
    tail -f ./logs/catalina.out
}

##############################################################################
###       发布流程 return 0 正常 return 1 不正常
##############################################################################
function deploy_flow(){

    #不直接上传，检出代码，打包
    if [[ "$dirct_upload" != "-du" ]]; then
        #检出代码
        checkout_code
        #编译代码
        package
    fi

    #检查war包是否存在
    check_war
    war_exist=$?
    #war包不存在, 检出代码并打包
    if [[ "$war_exist" = "1" ]]; then
        #检出代码
        checkout_code
        #编译代码
        package

        #二次检查war包是否存在，war包不存在退出
        check_war
        war_exist=$?
        #war包不存在, 检出代码并打包
        if [[ "$war_exist" = "1" ]]; then
            echo "发布失败：war包不存在"
            return 1
        fi
    fi

    #上传代码到服务器,并重启服务
    if [[ "$local_or_remote" = "-l" ]]; then
        local_copy
        restart_local_server
    elif [[ "$local_or_remote" = "-r" ]]; then
        remote_copy
        restart_remote_server
    else
        local_copy
        restart_local_server
    fi
    return 0
}

##############################################################################
###       输出参数详情
##############################################################################
function echo_params(){
    echo "[info] REMOTE SERVER INFO"
    echo "[info] ------------------------------------------------------------------------"
    echo "[info] remote_server_paths = ${remote_server_paths[@]}"
    echo "[info] remote_users = ${remote_users[@]}"
    echo "[info] remote_ips = ${remote_ips[@]}"
    echo "[info] remote_ports = ${remote_ports[@]}"
    echo "[info] remote_pwds = ${remote_pwds[@]}"
    echo "[info] remote_profiles = ${remote_profiles[@]}"
    echo "[info] remote_server_flags = ${remote_server_flags[@]}"
    echo "[info] remote_shell_dir = ${remote_shell_dir}"
    echo "[info] remote_shell_name = ${remote_shell_name}"
    echo "[info] remote_max_backup_file_num = ${remote_max_backup_file_num}"
    echo "[info] remote_backup_switch = ${remote_backup_switch}"
    echo "[info] ------------------------------------------------------------------------"
    echo "[info] LOCAL SERVER INFO"
    echo "[info] ------------------------------------------------------------------------"
    echo "[info] local_server_path = $local_server_path"
    echo "[info] ------------------------------------------------------------------------"
    echo "[info] PROJECT INFO"
    echo "[info] ------------------------------------------------------------------------"
    echo "[info] remote_project_basepath = $remote_project_basepath"
    echo "[info] local_project_basepath = $local_project_basepath"
    echo "[info] project_name = $project_name"
    echo "[info] war_sub_project_name = $war_sub_project_name"
    echo "[info] war_name = $war_name"
    echo "[info] local_profile = $local_profile"
    echo "[info] ------------------------------------------------------------------------"
    echo "[info] CHECKOUT_COMMAND INFO"
    echo "[info] ------------------------------------------------------------------------"
    echo "[info] checkout_command = ${checkout_command[@]}"
    echo "[info] ------------------------------------------------------------------------"
    echo "[info] MAVEN INFO"
    echo "[info] ------------------------------------------------------------------------"
    echo "[info] maven_home = $maven_home"
    echo "[info] ------------------------------------------------------------------------"
    echo "[info] REPOSITORY INFO"
    echo "[info] ------------------------------------------------------------------------"
    echo "[info] repository_url = $repository_url"
    echo "[info] ------------------------------------------------------------------------"
    echo "[info] BUILD INFO"
    echo "[info] ------------------------------------------------------------------------"
    echo "[info] parent_project_path = $parent_project_path"
    echo "[info] sub_project_path = $sub_project_path"    
    echo "[info] war_path = $war_path"
    echo "[info] profile = $profile"
    echo "[info] server_flag = $server_flag" 
    echo "[info] server_path = $server_path" 
    echo "[info] local_or_remote = $local_or_remote" 
    echo "[info] dirct_upload = $dirct_upload" 
    echo "[info] clean_project = $clean_project" 
    echo "[info] show_help_flag = $show_help_flag" 
    echo "[info] maven_shell = $maven_shell"
    echo "[info] backup_version = $backup_version"
    echo "[info] remote_server_path = $remote_server_path"
    echo "[info] remote_backup_path = $remote_backup_path"
    echo "[info] remote_user = $remote_user" 
    echo "[info] remote_ip = $remote_ip" 
    echo "[info] remote_port = $remote_port" 
    echo "[info] remote_pwd = $remote_pwd" 
    echo "[info] ------------------------------------------------------------------------"
    echo ""
}

function version(){
    echo "[info] atb version \"1.0.2\"" 
    echo "[info] project link: http://git.oschina.net/houjinxin/auto_build_shell" 
    echo "[info] ------------------------------------------------------------------------"
}

show_banner
##############################################################################
###    变量声明 var=value 等号必须前后紧挨着
##############################################################################
if   [[ ! -n ${ATB_HOME} ]]; 
then 
    echo "[info] "
    echo "[info] 环境变量ATB_HOME未设置，请设置后再执行"
    exit 0
else 
    echo "[info] "
    echo "[info] ATB_HOME INFO"
    echo "[info] ------------------------------------------------------------------------"
    echo "[info] ATB_HOME : ${ATB_HOME}"
    echo "[info] ------------------------------------------------------------------------"
fi
#配置文件路径名称
# conf_filename=~/conf.ini
conf_filename=${ATB_HOME}/conf/conf.ini
#以下参数代表服务器配置信息有多少机器配置多少个,这里的配置用于取值
#远程服务器路径
remote_server_paths=( $( read_ini ${conf_filename} remote-server config_remote_server_paths ) ) 
#远程服务器用户
remote_users=( $( read_ini ${conf_filename} remote-server config_remote_users ) ) 
#远程服务器ip
remote_ips=( $( read_ini ${conf_filename} remote-server config_remote_ips ) ) 
#远程服务器端口
remote_ports=( $( read_ini ${conf_filename} remote-server config_remote_ports ) ) 
#远程服务器密码 可以不设置
remote_pwds=( $( read_ini ${conf_filename} remote-server config_remote_pwds ) ) 
#maven打包用的远程profiles
remote_profiles=( $( read_ini ${conf_filename} remote-server config_remote_profiles ) ) 
#远程server_flags
remote_server_flags=( $( read_ini ${conf_filename} remote-server config_remote_server_flags ) )  
#远程重启shell目录 将restart脚本放到远程服务器指定的目录下，即可远程重启tomcat
remote_shell_dir=( $( read_ini ${conf_filename} remote-server config_remote_shell_dir ) ) 
#服务器上最大备份文件数
remote_max_backup_file_num=( $( read_ini ${conf_filename} remote-server config_remote_max_backup_file_num ) ) 
#备份功能开关
remote_backup_switch=( $( read_ini ${conf_filename} remote-server config_remote_backup_switch ) )

#本地tomcat webapps目录
local_server_path=( $( read_ini ${conf_filename} local-server config_local_server_path ) ) 

#项目远程build路径
remote_project_basepath=( $( read_ini ${conf_filename} project config_remote_project_basepath ) )
#项目本地路径
local_project_basepath=( $( read_ini ${conf_filename} project config_local_project_basepath ) )
#项目名称
project_name=( $( read_ini ${conf_filename} project config_project_name ) )
#war包所在的maven子模块,只支持一个war包的工程 为空时代表在父及目录下的target中存在war包
war_sub_project_name=( $( read_ini ${conf_filename} project config_war_sub_project_name ) )
#本地profile
local_profile=( $( read_ini ${conf_filename} project config_local_profile ) ) 
#war包名
war_name=( $( read_ini ${conf_filename} project config_war_name ) )

#代码检出命令
checkout_command=( $( read_ini ${conf_filename} command config_checkout_command ) )

#SVN账号
svn_username=( $( read_ini ${conf_filename} svn-authentication config_svn_username ) )

#SVN密码
svn_password=( $( read_ini ${conf_filename} svn-authentication config_svn_password ) )

#maven本地路径
maven_home=( $( read_ini ${conf_filename} maven config_maven_home ) )

#项目git或svn地址
repository_url=( $( read_ini ${conf_filename} repository config_repository_url ) )

#父工程路径
parent_project_path="${local_project_basepath}/${project_name}"
#子工程路径
sub_project_path="${parent_project_path}/${war_sub_project_name}"
#war包路径
war_path="${sub_project_path}/target/${war_name}"

#maven打包使用的profile
profile=""
#远程服务器标识,用于区分多台机器
server_flag=""
#最终server_path
server_path=""

#本地或远程部署
local_or_remote=""
#直接上传
dirct_upload=""
#clean工程
clean_project=""
#帮助标志
show_help_flag=""
#maven_shell
maven_shell=""

#远程tomcat webapps目录
remote_server_path=""
#远程服务器用户
remote_user=""
#远程服务器ip
remote_ip=""
#远程服务器端口
remote_port=""
#远程服务器密码 可以不设置
remote_pwd=""

#远程服务器上备份存储路径 默认为tomcat目录下的backup
remote_backup_path=""
#远程服务器上备份历史
remote_backup_history=""
#远程重启脚本名称
remote_shell_name="restart.sh"
#备份版本号
backup_version=""

##############################################################################
###    参数预处理
##############################################################################

#如果参数为0，各个参数取默认值
if [[ $# -eq 0 ]]; then
    dirct_upload=""
    # echo "handle dirct_upload : $dirct_upload"
    local_or_remote="-l"
    # echo "handle local_or_remote : $local_or_remote"
    clean_project=""
    # echo "handle clean_project : $clean_project"
else
    while [ -n "$1" ]
    do 
        # numcheck=$(check_num $1)
        # versioncheck=$(check_version $1)
        case "$1" in
        -du      ) dirct_upload="-du"                 ;;
        -h       ) show_help_flag="-h"                ;;
        -r       ) local_or_remote="-r";
                   parent_project_path="${remote_project_basepath}/${project_name}"
                                                    ;;
        -l       ) local_or_remote="-l"               ;;
        -c       ) clean_project="-c"                 ;;
        -his     ) remote_backup_history="-his"       ;;
        -rb      ) remote_rollback="-rb"              ;;
        [0-9]*   ) server_flag="$1"                   ;;
        *_[0-9]* ) backup_version="$1"                ;;
        -i       ) init;  exit 0                      ;;
        -v       ) version;  exit 0                      ;;
        *        ) echo "$1 is invalid"; exit 0;      ;;
        esac
        shift
    done

fi


#server_path以及profile配置
if [[ "${local_or_remote}" = "-l" ]]; then
    server_path="${local_server_path}"
    profile="${local_profile}"
elif [[ "${local_or_remote}" = "-r" ]]; then
    if [[ "$server_flag" = "" ]]; then
        echo "server_flag没有指定，请指定后再执行"
        exit 0
    fi

    if [[ ${remote_server_flags[@]} =~ ${server_flag} ]]; then
        #远程服务器服务器配置信息控制
        arr_index=0
        for i in "${!remote_server_flags[@]}"; do
            if [[ $server_flag = ${remote_server_flags[$i]} ]]; then
                 #statements
                 arr_index=$i
            fi 
        done
        # echo "服务器配置索引 $arr_index"
        remote_user="${remote_users[$arr_index]}"
        remote_ip="${remote_ips[$arr_index]}"
        remote_port="${remote_ports[$arr_index]}"
        remote_pwd="${remote_pwds[$arr_index]}"
        remote_server_path="${remote_server_paths[$arr_index]}"

        server_path="${remote_server_path}"
        remote_backup_path="${server_path}/backup"
        profile="${remote_profiles[${arr_index}]}"
    else
        echo "server_flag=${server_flag} 不在配置中，请确定后再执行"
        exit 0
    fi
    
else # 默认本地发布
    server_path="${local_server_path}"
    profile="${local_profile}"
fi

if [[ "$maven_home" != "" ]]; then
    maven_shell="${maven_home}/bin/mvn"
else
    maven_shell="mvn"
fi

##############################################################################
###    命令局部
##############################################################################
command_ssh=(ssh -t -T -p ${remote_port} ${remote_user}@${remote_ip})

#debug时查看参数输出
echo_params

if [[ "$clean_project" = "-c" ]]; then
    echo "工程clean开始，进入工程目录 $parent_project_path"
    cd "$parent_project_path"
    #如果是clean工程命令，执行完直接退出
    clear_project
    echo "工程clean结束"
    exit 0
elif [[ "$show_help_flag" = "-h" ]]; then
    #如果是help命令，显示帮助直接退出
    show_help
    exit 0
elif [[ "$remote_backup_history" = "-his" ]]; then
    #显示备份历史
    show_deploy_history
    exit 0
elif [[ "$remote_rollback" = "-rb" ]]; then
    if [[ -n "$backup_version" ]]; then
        #回滚
        rollback_backup_version
        exit 0
    fi
    echo "backup_version没有指定，请指定后再执行"
    exit 0
else
    echo "工程自动化构建开始，进入工程目录 $parent_project_path"
    cd "$parent_project_path"
    #其他情况执行发布流程
    deploy_flow
    echo "工程自动化构建结束"
    exit 0
fi
