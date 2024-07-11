#!/bin/bash

TS_VERSION="3.13.7"
TS_USER="teamspeak"
TeamSpeak_DIR="/opt/teamspeak"
DOWNLOAD_URL="https://files.teamspeak-services.com/releases/server/$TS_VERSION/teamspeak3-server_linux_amd64-$TS_VERSION.tar.bz2"

#Colorful Codes
red(){ echo -e "\033[31m\033[01m$1\033[0m";}
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
yellow(){ echo -e "\033[33m\033[01m$1\033[0m";}
blue(){ echo -e "\033[36m\033[01m$1\033[0m";}
white(){ echo -e "\033[37m\033[01m$1\033[0m";}
readp(){ read -p "$(yellow "$1")" $2;}

# 输入检查
check_input() {
    if [[ $1 != "1" && $1 != "yes" && $1 != "2" && $1 != "no" && ! -z $1 ]]; then
        red "输入错误,请重新选择"
        return 1
    fi
    return 0
}

# 安装所需工具
yellow "正在安装依赖..."
sudo apt update
sudo apt install -y wget bzip2 tar

# 下载并解压TeamSpeak服务器
yellow "正在下载TeamSepak服务器..."
sudo mkdir -p $TeamSpeak_DIR
cd $TeamSpeak_DIR
sudo wget $DOWNLOAD_URL -O teamspeak.tar.bz2
sudo tar xvjf teamspeak.tar.bz2
sudo rm teamspeak.tar.bz2

# 设置权限
blue "正在设置权限..."
sudo chown -R $(whoami):$(whoami) $TeamSpeak_DIR


# 配置防火墙
blue "开始配置防火墙..."
sudo ufw enable

while : ; do
    readp "是否自动放行端口?\n1、是，执行(回车默认)\n2、否,跳过!自行处理\n请选择: " AUTO_ALLOW
    check_input "$AUTO_ALLOW"
    [[ $? -eq 0 ]] && break
done

if [[ -z $AUTO_ALLOW ]] || [[ $AUTO_ALLOW == "1" || $AUTO_ALLOW == "yes" ]]; then
    while : ; do
        readp "是否自动放行默认TeamSpeak端口9987 (UDP)?\n1、是，执行(回车默认)\n2、否,跳过!自行处理\n请选择: " OPEN_Voice
        check_input "$OPEN_Voice"
        [[ $? -eq 0 ]] && break
    done
    if [[ -z $OPEN_Voice ]] || [[ $OPEN_Voice == "1" || $OPEN_Voice == "yes" ]]; then
        sudo ufw allow 9987/udp
        if [[ $? -eq 0 ]]; then
            green "已放行端口9987 (UDP)"
        else
            red "放行端口9987 (UDP)失败"
        fi
    else
        red "注意：请手动放行端口9987 (UDP)"
    fi

    while : ; do
        readp "是否自动放行文件传输端口30033 (TCP)?\n1、是，执行(回车默认)\n2、否,跳过!自行处理\n请选择: " OPEN_FILE
        check_input "$OPEN_FILE"
        [[ $? -eq 0 ]] && break
    done
    if [[ -z $OPEN_FILE ]] || [[ $OPEN_FILE == "1" || $OPEN_FILE == "yes" ]]; then
        sudo ufw allow 30033/tcp
        if [[ $? -eq 0 ]]; then
            green "已放行端口30033 (TCP)"
        else
            red "放行端口30033 (TCP)失败"
        fi
    else
        red "注意：请手动放行端口30033 (TCP)"
    fi

    while : ; do
        readp "是否自动放行服务查询端口10011 (TCP)?\n1、是，执行(回车默认)\n2、否,跳过!自行处理\n请选择: " OPEN_SERVICE
        check_input "$OPEN_SERVICE"
        [[ $? -eq 0 ]] && break
    done
    if [[ -z $OPEN_SERVICE ]] || [[ $OPEN_SERVICE == "1" || $OPEN_SERVICE == "yes" ]]; then
        sudo ufw allow 10011/tcp
        if [[ $? -eq 0 ]]; then
            green "已放行端口10011 (TCP)"
        else
            red "放行端口10011 (TCP)失败"
        fi
    else
        red "注意：请手动放行端口10011 (TCP)"
    fi

    while : ; do
        readp "是否自动放行服务SSH查询端口10022 (TCP)?\n1、是，执行(回车默认)\n2、否,跳过!自行处理\n请选择: " OPEN_SERVICE_SSH
        check_input "$OPEN_SERVICE_SSH"
        [[ $? -eq 0 ]] && break
    done
    if [[ -z $OPEN_SERVICE_SSH ]] || [[ $OPEN_SERVICE_SSH == "1" || $OPEN_SERVICE_SSH == "yes" ]]; then
        sudo ufw allow 10022/tcp
        if [[ $? -eq 0 ]]; then
            green "已放行端口10022 (TCP)"
        else
            red "放行端口10022 (TCP)失败"
        fi
    else
        red "注意：请手动放行端口10022 (TCP)"
    fi

    green "防火墙规则已更新。"
else
    red "请手动放行所需端口。"
fi
# 防火墙部分结束

# 创建服务文件
blue "正在创建服务"
sudo tee /etc/systemd/system/teamspeak.service > /dev/null <<EOL
[Unit]
Description=TeamSpeak 3 Server
After=network.target

[Service]
WorkingDirectory=$TeamSpeak_DIR
User=$(whoami)
Group=$(whoami)
Type=forking
ExecStart=$TeamSpeak_DIR/ts3server_startscript.sh start
ExecStop=$TeamSpeak_DIR/ts3server_startscript.sh stop
ExecReload=$TeamSpeak_DIR/ts3server_startscript.sh restart
PIDFile=$TeamSpeak_DIR/ts3server.pid
Restart=always

[Install]
WantedBy=multi-user.target
EOL

green "服务文件创建成功"


# 重新加载systemd并启动TeamSpeak服务
sudo systemctl daemon-reload
while : ; do
        readp "服务文件已就绪,现在启动服务器吗?\n1、是，执行(回车默认)\n2、否,跳过!自行处理\n请选择: " START_SERVICE
        check_input "$START_SERVICE"
        [[ $? -eq 0 ]] && break
    done
    if [[ -z $START_SERVICE ]] || [[ $START_SERVICE == "1" || $START_SERVICE == "yes" ]]; then
        sudo systemctl start teamspeak
        sudo systemctl enable teamspeak
        
        if systemctl is-active --quiet teamspeak; then
            green "TeamSpeak服务器已启动!"
        else
            red "TeamSpeak服务器启动失败"
            yellow "使用以下命令查看服务状态: sudo journalctl -xeu teamspeak"
        fi

    else
        red "注意: TeamSpeak服务器还未启动,请在合适的时候进行手动启动"
        yellow "使用以下命令手动启动服务器: sudo systemctl start teamspeak"
    fi