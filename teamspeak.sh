#!/bin/bash

TS_VERSION="3.13.7"
TS_USER="teamspeak"
TeamSpeak_DIR="/opt/teamspeak"
DOWNLOAD_URL="https://files.teamspeak-services.com/releases/server/$TS_VERSION/teamspeak3-server_linux_amd64-$TS_VERSION.tar.bz2"

red(){ echo -e "\033[31m\033[01m$1\033[0m";}
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
yellow(){ echo -e "\033[33m\033[01m$1\033[0m";}
blue(){ echo -e "\033[36m\033[01m$1\033[0m";}
white(){ echo -e "\033[37m\033[01m$1\033[0m";}
readp(){ read -p "$(yellow "$1")" $2;}

# 更新系统并安装依赖
sudo apt update
sudo apt install -y wget bzip2 tar

# 创建TeamSpeak用户
echo "正在创建TeamSpeak用户..."
sudo adduser --disabled-login --no-create-home --gecos "TeamSpeak User" $TS_USER

# 下载并解压TeamSpeak服务器
echo "正在下载TeamSepak服务器..."
sudo mkdir -p $TeamSpeak_DIR
cd $TeamSpeak_DIR
sudo wget $DOWNLOAD_URL -O teamspeak.tar.bz2
sudo tar xvjf teamspeak.tar.bz2
sudo rm teamspeak.tar.bz2

# 设置权限
echo "设置权限..."
sudo chown -R $TS_USER:$TS_USER $TeamSpeak_DIR

# 创建服务文件
echo "创建服务文件..."
sudo tee /etc/systemd/system/teamspeak.service > /dev/null <<EOL
[Unit]
Description=TeamSpeak 3 Server
After=network.target

[Service]
WorkingDirectory=$TeamSpeak_DIR
User=$TS_USER
Group=$TS_USER
Type=forking
ExecStart=$TeamSpeak_DIR/ts3server_startscript.sh start
ExecStop=$TeamSpeak_DIR/ts3server_startscript.sh stop
ExecReload=$TeamSpeak_DIR/ts3server_startscript.sh restart
PIDFile=$TeamSpeak_DIR/ts3server.pid
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# 重新加载systemd并启动TeamSpeak服务
echo "正在启动TeamSpeak服务..."
sudo systemctl daemon-reload
sudo systemctl start teamspeak
sudo systemctl enable teamspeak

# 开启防火墙端口
echo "正在配置防火墙..."
read -p "\n1、是，执行(回车默认)\n2、否，跳过！自行处理\n请选择：: " ENABLE_UFW
if [[ $ENABLE_UFW == "y" || $ENABLE_UFW == "Y" ]]; then
    sudo ufw enable
    
    read -p "是否打开文件传输端口(30033)?\n1、是，执行(回车默认)\n2、否，跳过！自行处理\n请选择： (y/n): " OPEN_30033
    if [[ $OPEN_30033 == "y" || $OPEN_30033 == "Y" ]]; then
        sudo ufw allow 30033/tcp
    fi

    read -p "打开查询端口(10011)? (y/n): " OPEN_10011
    if [[ $OPEN_10011 == "y" || $OPEN_10011 == "Y" ]]; then
        sudo ufw allow 10011/tcp
    fi
    
    echo "防火墙规则已更新。"
else
    echo "跳过防火墙配置。"
fi

# 配置防火墙
blue "配置防火墙..."
sudo ufw enable

readp "是否自动放行端口?\n1、是，执行(回车默认)\n2、否,跳过!自行处理\n请选择: " AUTO_ALLOW
if [[ -z $AUTO_ALLOW ]] || [[ $AUTO_ALLOW == "1" ]]; then
    readp "是否自动放行必要端口?\n1、是，执行(回车默认)\n2、否,跳过!自行处理\n请选择: " OPEN_Voice
    if [[ -z $OPEN_Voice ]] || [[ $OPEN_Voice == "1" ]]; then
        sudo ufw allow 9987/udp
        green "已放行端口9987 (UDP)"
    fi

    readp "是否自动放行文件传输端口?\n1、是，执行(回车默认)\n2、否,跳过!自行处理\n请选择: " OPEN_File
    if [[ -z $OPEN_File ]] || [[ $OPEN_File == "1" ]]; then
        sudo ufw allow 30033/tcp
        green "已放行端口30033 (TCP)"
    fi

    readp "是否自动放行服务查询端口?\n1、是，执行(回车默认)\n2、否,跳过!自行处理\n请选择: " OPEN_Service
    if [[ -z $OPEN_Service ]] || [[ $OPEN_Service == "1" ]]; then
        sudo ufw allow 10011/tcp
        green "已放行端口10011 (TCP)"
    fi

    readp "是否自动放行服务SSH查询端口?\n1、是，执行(回车默认)\n2、否,跳过!自行处理\n请选择: " OPEN_Service_SSH
    if [[ -z $OPEN_Service_SSH ]] || [[ $OPEN_Service_SSH == "1" ]]; then
        sudo ufw allow 10022/tcp
        green "已放行端口10022 (TCP)"
    fi

    green "防火墙规则已更新。"
else
    red "请手动放行所需端口。"
fi

echo "TeamSpeak服务器已成功安装并启动！"
echo "使用以下命令查看服务状态：sudo systemctl status teamspeak"
