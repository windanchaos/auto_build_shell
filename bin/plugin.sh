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
# 获取当前脚本所在目录
dir="$(dirname "$0")"

# 引入函数
# . $dir/functions/show_banner
# . $dir/functions/show_help
# . $dir/functions/echo_params
# . $dir/functions/version
# . $dir/functions/read_ini
# . $dir/functions/init
# . $dir/functions/log

# 引入插件
# . $dir/plugins/check

# 循环加载组件
for component in $dir/*/*; do
	echo $component
	. $component
done

show_banner
##############################################################################
###    变量声明 var=value 等号必须前后紧挨着
##############################################################################
if   [[ ! -n ${AT1B_HOME} ]]; 
then 
    warning ""
    warning "------------------------------------------------------------------------"
    warning "环境变量ATB_HOME未设置"
    warning "------------------------------------------------------------------------"
else 
    info ""
    info "ATB_HOME INFO"
    info "------------------------------------------------------------------------"
    info "ATB_HOME : ${ATB_HOME}"
    info "------------------------------------------------------------------------"
fi

if [[ "$maven_home" != "" ]]; then
    maven_shell="${maven_home}/bin/mvn"
else
    maven_shell="mvn"
fi

##############################################################################
###    处理选项参数
##############################################################################
while [ -n "$1" ]
do 
    # numcheck=$(check_num $1)
    # versioncheck=$(check_version $1)
    case "$1" in
    -du      ) dirct_upload="-du"                 ;;
    -h       ) show_help; exit 0;                 ;;
    -r       ) 
				local_or_remote="-r"
				shift #设定-r 后面默认是 server_flag
				server_flag=$1
			    if [[ "$server_flag" = "" ]]; then
			        error "[ server_flag ]没有指定，请指定后再执行"
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
			        # info "服务器配置索引 $arr_index"
			        remote_user="${remote_users[$arr_index]}"
			        remote_ip="${remote_ips[$arr_index]}"
			        remote_port="${remote_ports[$arr_index]}"
			        remote_pwd="${remote_pwds[$arr_index]}"
			        remote_server_path="${remote_server_paths[$arr_index]}"
			        
			        parent_project_path="${remote_project_basepath}/${project_name}";
			        sub_project_path="${parent_project_path}/${war_sub_project_name}"
			        war_path="${sub_project_path}/target/${war_name}"
			        server_path="${remote_server_path}"
			        remote_backup_path="${server_path}/backup"
			        profile="${remote_profiles[${arr_index}]}"
			        #ssh命令简写
					command_ssh=(ssh -t -T -p ${remote_port} ${remote_user}@${remote_ip})
			    else
			        error "[ server_flag = ${server_flag} ]不在配置中，请确定后再执行"
			        exit 0
			    fi
             ;;
    -l       ) 
				local_or_remote="-l"
				profile="${local_profile}"
				server_path="${local_server_path}"
             ;;
    -c       ) clear_project; exit 0;             ;;
    -his     ) show_deploy_history; exit 0        ;;
    -rb      )     
				if [[ -n "$backup_version" ]]; then
				    #回滚
			        rollback_backup_version
				else
					error "[ backup_version ]未指定，请指定后再执行"
				fi
				exit 0
             ;;
    *_[0-9]* ) backup_version="$1"                ;;
    -i       ) init;  exit 0                      ;;
    -v       ) show_version;  exit 0;             ;;
    *        ) error "$1 is invalid"; exit 0;     ;;
    esac
    shift
done

info "工程自动化构建开始，进入工程目录 $parent_project_path"
cd "$parent_project_path"
#其他情况执行发布流程
deploy_flow
info "工程自动化构建结束"
exit 0

