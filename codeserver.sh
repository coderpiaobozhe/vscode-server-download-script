# !/bin/sh
# 标志全部服务器是否都可以联网，为1表示可以，为0表示不可以。如果不能的话在本地下载文件传到服务器上
lk=0

index=0
hosts=""
usernames=""
ipaddresses=""

# 获取本地vscode信息

cmt=$(code --version | awk 'NR==2 {print $0}')
if [ $lk -eq 0 ];then
	if ls $HOME/vscode-server-linux-$plat.tar.gz* 1> /dev/null 2>&1;then
		rm -rf $HOME/vscode-server-linux-x64.tar.gz*
	fi
	wget -P $HOME https://vscode.download.prss.microsoft.com/dbazure/download/stable/$cmt/vscode-server-linux-x64.tar.gz
fi

# 读取`~/.ssh/config`文件中的内容

while IFS= read -r line; do
	case "$line" in
		Host[\ \t]*[0-9a-zA-Z_\-\.]*)
			# echo "Host->$line"
			if [ $index -gt 0 ];then
				echo "$index: $current_host - $current_user@$current_ip"
			fi
			current_host=$(echo "$line" | awk '{print $2}')
            		hosts="$hosts $current_host"
            		index=$((index+1))
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
            		;;
    	esac
done < $HOME/.ssh/config
echo "$index: $current_host - $current_user@$current_ip"

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
		echo "Host $host" >> $HOME/.ssh/config
		echo "  HostName $ip" >> $HOME/.ssh/config
		echo "  User $user" >> $HOME/.ssh/config
		echo "" >> $HOME/.ssh/config
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
    		scp "$HOME/vscode-server-linux-x64.tar.gz" "$user@$ip:~"
    	fi
    	ssh -T "$user@$ip" <<EOF
	remote_download()
	{
		commit="\$1"
		linkedtoweb="\$2"
		test -d \$HOME/.vscode-server/bin || mkdir -p \$HOME/.vscode-server/bin
		cd \$HOME/.vscode-server/bin
		if [ "\$linkedtoweb" = "1" ]; then
			wget https://vscode.download.prss.microsoft.com/dbazure/download/stable/\$commit/vscode-server-linux-x64.tar.gz
   		else
     			mv \$HOME/vscode-server-linux-x64.tar.gz ./
		fi
		if [ ! -d "\$commit" ]; then
			tar -zxf vscode-server-linux-x64.tar.gz
			mv vscode-server-linux-x64 \$commit
		fi
		rm vscode-server-linux-x64.tar.gz
	}
	remote_download "$cmt" "$lk"
EOF
done

if [ $lk -eq 0 ];then
	rm -rf $HOME/vscode-server-linux-x64.tar.gz
fi

echo "vscode-server已配置完毕。"
