#!/bin/bash
set -e

CONFIG_DIR="/etc/hysteria"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
LOG_PATH="/var/log/hysteria.log"
INSTALL_PATH="/usr/local/bin/hysteria"
HY_BIN_URL="https://download.hysteria.network/app/latest/hysteria-linux-arm64"
THIS_SCRIPT="$(readlink -f "$0")"

function install_hysteria() {
  # ...（同之前，这里省略安装部分）
  # 只把监听端口、密码保存为全局变量，方便后续查看配置时用
  # 这里强制写入文件，方便后边读取（可将端口和密码写到独立文件）

  # 提取用户输入的监听端口和密码，保存到文件以便show_config读取
  echo "$LISTEN_PORT" > "$CONFIG_DIR/.listen_port"
  echo "$PASSWORD" > "$CONFIG_DIR/.password"

  # .... 其他内容同之前展示
}

function show_client_config() {
  if [[ ! -f "$CONFIG_DIR/.listen_port" || ! -f "$CONFIG_DIR/.password" ]]; then
    echo "未找到端口或密码信息，请先创建代理。"
    return
  fi

  LISTEN_PORT=$(cat "$CONFIG_DIR/.listen_port")
  PASSWORD=$(cat "$CONFIG_DIR/.password")

  SERVER_IP=$(curl -s https://ipinfo.io/ip || echo "IP获取失败")
  COUNTRY_CODE=$(curl -s https://ipinfo.io/country | tr -d '\n' || echo "XX")

  echo
  echo "🔗 当前客户端连接字符串："
  echo "hy2://$PASSWORD@${SERVER_IP}:${LISTEN_PORT}?sni=bing.com&insecure=1#${SERVER_IP}-${COUNTRY_CODE}"
  echo
}

function uninstall_hysteria() {
  echo "停止 hysteria 服务..."
  pkill hysteria || echo "服务未运行或已停止"

  echo "删除程序文件..."
  rm -f "$INSTALL_PATH"

  echo "删除配置及证书..."
  rm -rf "$CONFIG_DIR"

  echo "删除日志文件..."
  rm -f "$LOG_PATH"

  # 删除当前脚本本身
  echo "删除面板脚本文件自身：$THIS_SCRIPT"
  rm -f "$THIS_SCRIPT" && echo "脚本文件已删除。"

  echo "完成卸载。"
}

function main_menu() {
  while true; do
    echo "==================================="
    echo "     Hysteria 微型管理面板"
    echo "==================================="
    echo "1) 创建并启动 hy2 代理"
    echo "2) 查看客户端连接字符串"
    echo "3) 删除 hysteria 及面板脚本"
    echo "4) 退出"
    echo -n "请选择操作 [1-4]: "

    read -r choice
    case $choice in
      1) install_hysteria ;;
      2) show_client_config ;;
      3)
        echo -n "确认删除 hysteria 程序、配置及删除本脚本？(y/n): "
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
          uninstall_hysteria
          exit 0
        else
          echo "取消删除。" 
        fi
        ;;
      4)
        echo "退出脚本。"
        exit 0
        ;;
      *)
        echo "无效选项，请重新输入。"
        ;;
    esac
    echo
  done
}

main_menu
