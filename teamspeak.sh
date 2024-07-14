#!/bin/bash

TS_VERSION="3.13.7"
TEMP_DIR=$(mktemp -d)  # 指定临时目录路径
TeamSpeak_DIR="/opt/teamspeak"  # 指定目标安装目录
DOWNLOAD_URL="https://files.teamspeak-services.com/releases/server/$TS_VERSION/teamspeak3-server_linux_amd64-$TS_VERSION.tar.bz2"

# Colorful Codes
red() { echo -e "\033[31m\033[01m$1\033[0m"; }
green() { echo -e "\033[32m\033[01m$1\033[0m"; }
yellow() { echo -e "\033[33m\033[01m$1\033[0m"; }
blue() { echo -e "\033[36m\033[01m$1\033[0m"; }
white() { echo -e "\033[37m\033[01m$1\033[0m"; }
readp() { read -p "$(yellow "$1")" $2; }

# 输入检查
check_input() {
    if [[ $1 != "1" && $1 != "yes" && $1 != "y" && $1 != "2" && $1 != "no" && $1 != "n" && ! -z $1 ]]; then
        red "输入错误,请重新选择"
        return 1
    fi
    return 0
}

# 安装所需工具
yellow "正在安装所需依赖..."
sudo apt update
sudo apt install -y wget bzip2 tar

# 继续操作选项
readp "是否继续操作? \n1、是,继续操作\n2、否,退出脚本\n请选择: " CONTINUE

if [[ -z "$CONTINUE" || "$CONTINUE" == "2" || "$CONTINUE" == "n" || "$CONTINUE" == "no" ]]; then
    red "操作已取消,脚本退出。"
    exit 0
elif [[ "$CONTINUE" != "1" && "$CONTINUE" != "y" && "$CONTINUE" != "yes" ]]; then
    red "输入错误,脚本退出。"
    exit 1
fi

# 检查是否已安装
if [[ -d "$TeamSpeak_DIR" ]]; then
    green "TeamSpeak 服务器已安装，要覆盖安装吗？"
    readp "是否重新安装? \n1、是,重新安装\n2、否,退出脚本\n请选择: " REINSTALL

    if [[ -z "$REINSTALL" || "$REINSTALL" == "2" || "$REINSTALL" == "n" || "$REINSTALL" == "no" ]]; then
        red "TeamSpeak已经安装,此脚本退出。"
        exit 0
    elif [[ "$REINSTALL" == "1" || "$REINSTALL" == "y" || "$REINSTALL" == "yes" ]]; then
        sudo rm -rf "$TeamSpeak_DIR/teamspeak3-server_linux_amd64"
        green "已删除旧的安装文件。"
    else
        red "输入错误,脚本退出。"
        exit 1
    fi
fi

# 下载并解压TeamSpeak服务器
blue "正在下载TeamSpeak服务器文件..."
if ! wget -qP "$TEMP_DIR" "$DOWNLOAD_URL"; then
    red "下载 TeamSpeak 服务器文件失败"
    exit 1
fi
green "服务器文件下载成功"

# 确保目标安装目录存在
sudo mkdir -p "$TeamSpeak_DIR"

# 解压文件到目标安装目录
if ! sudo tar xvjf "$TEMP_DIR/teamspeak3-server_linux_amd64-$TS_VERSION.tar.bz2" -C "$TeamSpeak_DIR" --strip-components=1; then
    red "解压 TeamSpeak 服务器文件失败"
    exit 1
fi

# 删除临时文件
rm -rf "$TEMP_DIR"

# 设置权限
sudo chown -R "$(whoami)":"$(whoami)" $TeamSpeak_DIR

# 配置防火墙
blue "开始配置防火墙..."

while : ; do
    readp "是否自动放行端口?\n1、是,执行(回车默认)\n2、否,跳过!自行处理\n请选择: " AUTO_ALLOW
    check_input "$AUTO_ALLOW"
    [[ $? -eq 0 ]] && break
done

if [[ -z $AUTO_ALLOW ]] || [[ $AUTO_ALLOW == "1" || $AUTO_ALLOW == "yes" ]]; then
    while : ; do
        readp "是否自动放行默认TeamSpeak端口9987 (UDP)?\n1、是,执行(回车默认)\n2、否,跳过!自行处理\n请选择: " OPEN_Voice
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
        red "注意:请手动放行端口9987 (UDP)"
    fi

    while : ; do
        readp "是否自动放行文件传输端口30033 (TCP)?\n1、是,执行(回车默认)\n2、否,跳过!自行处理\n请选择: " OPEN_FILE
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
        red "注意:请手动放行端口30033 (TCP)"
    fi

    while : ; do
        readp "是否自动放行服务查询端口10011 (TCP)?\n1、是,执行(回车默认)\n2、否,跳过!自行处理\n请选择: " OPEN_SERVICE
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
        red "注意:请手动放行端口10011 (TCP)"
    fi

    while : ; do
        readp "是否自动放行服务SSH查询端口10022 (TCP)?\n1、是,执行(回车默认)\n2、否,跳过!自行处理\n请选择: " OPEN_SERVICE_SSH
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
        red "注意:请手动放行端口10022 (TCP)"
    fi

    green "防火墙配置完成。"
else
    red "请手动放行所需端口。"
fi

# 创建服务文件
blue "正在创建服务"
sudo tee /etc/systemd/system/teamspeak.service > /dev/null <<EOL
[Unit]
Description=TeamSpeak 3 Server
After=network.target

[Service]
User=$(whoami)
Group=$(whoami)
WorkingDirectory=$TeamSpeak_DIR
ExecStart=$TeamSpeak_DIR/ts3server_startscript.sh start
ExecStop=$TeamSpeak_DIR/ts3server_startscript.sh stop
PIDFile=$TeamSpeak_DIR/ts3server.pid
Restart=always
Type=forking

[Install]
WantedBy=multi-user.target
EOL

touch "$TeamSpeak_DIR/.ts3server_license_accepted"
green "服务文件创建成功"

# 重新加载 systemd 并启动 TeamSpeak 服务器

while : ; do
    readp "服务文件已就绪,现在启动服务器吗?\n1、是,执行(回车默认)\n2、否,跳过!自行处理\n请选择: " START_SERVICE
    if [[ -z "$START_SERVICE" || "$START_SERVICE" == "1" || "$START_SERVICE" == "yes" ]]; then
        sudo systemctl daemon-reload
        sudo systemctl enable teamspeak >/dev/null 2>&1
        sudo systemctl start teamspeak
        if sudo systemctl is-active --quiet teamspeak; then
            green "TeamSpeak服务器已启动!"
        else
            red "TeamSpeak服务器启动失败,请检查日志。"
            yellow "使用以下命令查看服务状态: sudo journalctl -xeu teamspeak"
            echo "apikey=$(systemctl status teamspeak | grep -oP 'apikey=\s*\K\S+')" > ~/token.txt
            echo "token=$(systemctl status teamspeak | grep -oP 'token=\K\S+')" >> ~/token.txt
            green "已将TeamSpeak管理所需的APIKEY以及TOKEN写入到文件内:"
            echo -e "$(green "可使用以下命令进行查看:") $(blue "cat ~/token.txt")"
        fi
        exit 0
    elif [[ "$START_SERVICE" == "2" ]]; then
        red "注意: TeamSpeak服务器还未启动,请在合适的时候进行手动启动"
        yellow "使用以下命令手动启动服务器: sudo systemctl enable teamspeak --now"
        exit 0
    else
        red "输入错误,请重新选择"
    fi
done