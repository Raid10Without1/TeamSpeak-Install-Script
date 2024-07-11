#!/bin/bash

# 定义一些变量
TS_VERSION="3.13.7" # 替换为你想要的TeamSpeak服务器版本
TS_USER="teamspeak"
TeamSpeak_DIR="/opt/teamspeak"
DOWNLOAD_URL="https://files.teamspeak-services.com/releases/server/$TS_VERSION/teamspeak3-server_linux_amd64-$TS_VERSION.tar.bz2"

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

echo "TeamSpeak服务器已成功安装并启动！"
echo "使用以下命令查看服务状态：sudo systemctl status teamspeak"
