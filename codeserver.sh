# !/bin/sh
#
#
# vscode-server 下载方法说明
#
#
# 作者：coderpiaobozhe
#
#
# 零、使用方法
#
#
# 1. 本脚本是在本地设备上执行的。使用本脚本前建议先把本地设备上的ssh公钥上传到服务器上，让本地设备能免密登录服务器；
#
# 2. 本脚本假设本地设备是能联网的，而服务器则不一定可以。
#
# 3. 如果本地设备的操作系统是某个Linux发行版(或者其他能直接运行shell脚本的系统)，那本脚本是可以直接运行的；如果是windows系统（或者其他不能直接运行shell脚本的系统），那你需要下载git和wget，在git提供的终端里面运行本脚本，亲测有效；
#
# 4. 给这个脚本赋予执行权限并执行它：chmod +x codeserver.sh && ./codeserver.sh,接下来根据提示操作即可；
#
#
# 一、vscode-server是如何工作的
#
#
# 1. 使用vscode远程连接到服务器上需要在服务器上下载vscode-server；
#
# 2. .vscode-server的内部目录结构如下：
# |-.vscode-server
# 	|-bin
#   		|-${commit id1}
#		|-${commit id2}
#		|-...
# 	|-data（不一定有）
# 	|-extensions（不一定有）
#	|-...
# 3. 每个版本的vscode都对应一个commit id，当远程连接到服务器时，本地设备上vscode的commit id会被传上去；
#
# 4. 如果在.vscode-server/bin/目录下有与传上去的commit id同名的文件夹，服务器会直接完成远程链接的相关工作；
#
# 5. 如果不符合第4步中提到的情况，在完成远程连接的相关工作前，服务器就会试图从vscode官方提供的网站下载对应的文件并把它们放到相应的目录下；
#
# 6. vscode每次更新版本时就会换commit id，所以每次更新后服务器都会执行第5步中提到的操作；
#
#
# 二、为什么vscode有时不能完成上述工作以至于需要我们自行完成相关操作
#
#
# 自2023年的某月始，出于某些未知原因，vscode官方提供的网站https://update.code.visualstudio.com无法稳定访问。因此，我们需要把该网址换成国内的cdn https://vscode.cdn.azure.cn
#
#
# 三、常见问题
#
#
# 问：本脚本能彻底解决vscode ssh连接问题吗？
#
# 答：暂时不能。首先，有的服务器是没法联网的，对于这些服务器，惟一的解决方法就是在本地下载文件然后传到服务器上，但这个方法对于能联网的服务器就不太合适；其次，config文件的配置形式是多种多样的：ssh端口可以换，proxyjump也可以设置。如何处理config文件中的内容我暂时还没想好。
#
# 问：为什么不默认用bash执行？
#
# 答：因为我本人用的zsh，为了提高脚本兼容性，所以选择最基础的sh。
#
# 问：能不能出一个windows系统下直接运行的batch脚本？
#
# 答：暂无这个计划，毕竟windows上也能靠git的终端运行这个脚本。当然了，最主要的问题是我不会batch语法。
#
#
# 运行内容
#
#
# 标志全部服务器是否都可以联网，为1表示可以，为0表示不可以。如果不能的话在本地下载文件传到服务器上
lk=0

index=1
hosts=""
usernames=""
ipaddresses=""

# 获取本地vscode信息

cmt=$(code --version | awk 'NR==2 {print $0}')
plat=$(code --version | awk 'NR==3 {print $0}')
if [ $lk -eq 0 ];then
	wget https://vscode.cdn.azure.cn/stable/$cmt/vscode-server-linux-$plat.tar.gz
fi

# 读取`~/.ssh/config`文件中的内容

while IFS= read -r line; do
	case "$line" in
		Host[\ \t]*[0-9a-zA-Z_\-\.]*)
			# echo "Host->$line"
			current_host=$(echo "$line" | awk '{print $2}')
            		hosts="$hosts $current_host"
            		;;
        	[\ \t]*HostName[\ \t]*[0-9a-zA-Z_\-\.]*)
            		# echo "HostName->$line"
            		current_ip=$(echo "$line" | awk '{print $2}')
            		ipaddresses="$ipaddresses $current_ip"
            		;;
        	[\ \t]*User[\ \t]*[0-9a-zA-Z_\-\.]*)
            		# echo "User->$line"
            		current_user=$(echo "$line" | awk '{print $2}')
            		usernames="$usernames $current_user"
            		echo "$index: $current_host - $current_user@$current_ip"
            		index=$((index+1))
            		;;
    	esac
done < ~/.ssh/config

# 让用户选择要在哪些服务器上执行操作

read -p "请输入要执行操作的服务器序号，多个服务器请用逗号分隔，如果需要添加几台服务器就输入几个0，范围选择请用短横线（如0-5）: " selected
raw_selected_hosts=$(echo $selected | tr ',' ' ')
selected_hosts=""
for i in $raw_selected_hosts; do
	case "$i" in
		[0-9]*\-[0-9]*)
			tmp=$(echo "$i" | tr '-' ' ')
			lrange=$(echo "$tmp" | awk '{print $1}')
			rrange=$(echo "$tmp" | awk '{print $2}')
			j="$lrange"
			while [ "$j" -le "$rrange" ]; do
				selected_hosts="$selected_hosts $j"
				j=$((j+1))
			done
			;;
		[0-9]*)
			selected_hosts="$selected_hosts $i"
			;;
	esac
done

for i in $selected_hosts; do
	if [ $i -eq 0 ];then
		read -p "请输入新服务器的Host名称: " host
		read -p "请输入新服务器的IP地址: " ip
		read -p "请输入新服务器的用户名: " user
		echo "\nHost $host\n  HostName $ip\n  User $user" >> ~/.ssh/config
	else
	    	set -- $hosts
	    	host=$(eval echo \$$i)
	    	set -- $usernames
	    	user=$(eval echo \$$i)
	    	set -- $ipaddresses
	    	ip=$(eval echo \$$i)
	    	# echo "$host - $user@$ip"
    	fi
    	if [ $lk -eq 0 ]; then
    		scp "vscode-server-linux-$plat.tar.gz" "$user@$ip:~/.vscode-server/bin"
    	fi
    	ssh -T "$user@$ip" <<EOF
	remote_download()
	{
		commit="\$1"
		platform="\$2"
		linkedtoweb="\$3"
		test -d ~/.vscode-server/bin || mkdir -p ~/.vscode-server/bin
		cd ~/.vscode-server/bin
		if [ "\$linkedtoweb" = "1" ]; then
			wget https://vscode.cdn.azure.cn/stable/\$commit/vscode-server-linux-\$platform.tar.gz
		fi
		if [ ! -d "\$commit" ]; then
			tar -zxf vscode-server-linux-\$platform.tar.gz
			mv vscode-server-linux-\$platform \$commit
		fi
		rm vscode-server-linux-\$platform.tar.gz
	}
	remote_download "$cmt" "$plat" "$lk"
EOF
done

if [ $lk -eq 0 ];then
	rm -rf vscode-server-linux-$plat.tar.gz
fi

echo "vscode-server已配置完毕。"
cd ~
