#!/bin/bash
set -e

CONFIG_DIR="/etc/hysteria"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
LOG_PATH="/var/log/hysteria.log"
INSTALL_PATH="/usr/local/bin/hysteria"
THIS_SCRIPT="$(readlink -f "$0")"

# 检测架构并返回对应下载链接
function get_download_url() {
  local arch=$(uname -m)
  case "$arch" in
      x86_64|amd64)
          echo "https://download.hysteria.network/app/latest/hysteria-linux-amd64"
          ;;
      aarch64|arm64)
          echo "https://download.hysteria.network/app/latest/hysteria-linux-arm64"
          ;;
      armv7l)
          echo "https://download.hysteria.network/app/latest/hysteria-linux-armv7"
          ;;
      *)
          echo ""
          ;;
  esac
}

function install_hysteria() {
  echo "开始安装 hysteria2 代理..."

  echo "检测并安装依赖 curl wget openssl jq"
  if command -v apt-get &>/dev/null; then
      apt-get update -qq
      apt-get install -y curl wget openssl jq
  elif command -v yum &>/dev/null; then
      yum install -y curl wget openssl jq
  elif command -v apk &>/dev/null; then
      apk update
      apk add curl wget openssl jq
  else
      echo "未检测到 apt-get、yum 或 apk，请手动安装 curl wget openssl jq"
  fi

  HY_BIN_URL=$(get_download_url)
  if [[ -z "$HY_BIN_URL" ]]; then
    echo "检测到当前架构不支持自动下载 hysteria，请手动操作。"
    exit 1
  fi

  echo "检测架构: $(uname -m)，下载地址：$HY_BIN_URL"

  echo "下载 hysteria2 程序到 $INSTALL_PATH"
  curl -L -o "$INSTALL_PATH" "$HY_BIN_URL"
  chmod +x "$INSTALL_PATH"

  echo "创建配置目录：$CONFIG_DIR"
  mkdir -p "$CONFIG_DIR"

  echo "生成 EC 自签 TLS 证书（prime256v1）..."
  EC_PARAM_FILE=$(mktemp)
  openssl ecparam -name prime256v1 -out "$EC_PARAM_FILE"
  openssl req -x509 -nodes -newkey ec:"$EC_PARAM_FILE" \
      -keyout "$CONFIG_DIR/server.key" -out "$CONFIG_DIR/server.crt" -days 36500 \
      -subj "/CN=bing.com" >/dev/null 2>&1
  rm -f "$EC_PARAM_FILE"

  while true; do
    read -rp "请输入监听端口（默认 443）: " LISTEN_PORT
    LISTEN_PORT=${LISTEN_PORT:-443}
    if [[ $LISTEN_PORT =~ ^[0-9]+$ ]] && (( LISTEN_PORT>0 && LISTEN_PORT<65536 )); then
      break
    else
      echo "端口输入不合法，请输入 1-65535 之间的数字"
    fi
  done

  while true; do
    read -rp "请输入混淆密码（必填）: " PASSWORD
    if [[ -n "$PASSWORD" ]]; then
      break
    else
      echo "密码不能为空，请重新输入。"
    fi
  done

  cat > "$CONFIG_FILE" <<EOF
listen: :$LISTEN_PORT

tls:
  cert: $CONFIG_DIR/server.crt
  key: $CONFIG_DIR/server.key

auth:
  type: password
  password: $PASSWORD

masquerade:
  type: proxy
  proxy:
    url: https://bing.com/
    rewriteHost: true

up_mbps: 1000
down_mbps: 1000
disable_udp: false
EOF

  echo "$LISTEN_PORT" > "$CONFIG_DIR/.listen_port"
  echo "$PASSWORD" > "$CONFIG_DIR/.password"

  echo "启动 hysteria2 服务端..."
  pkill hysteria 2>/dev/null || true
  nohup "$INSTALL_PATH" server --config "$CONFIG_FILE" > "$LOG_PATH" 2>&1 &
  sleep 1

  echo "hysteria 已启动，监听端口: $LISTEN_PORT"
  echo
  echo "🔗 Hysteria2 客户端连接信息："
  echo "hy2://$PASSWORD@${SERVER_IP}:${LISTEN_PORT}?sni=bing.com&insecure=1#${SERVER_IP}-${COUNTRY_CODE}"
  echo
  echo "日志路径: $LOG_PATH"
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
  echo "🔗 Hysteria2 客户端连接信息："
  echo "hy2://$PASSWORD@${SERVER_IP}:${LISTEN_PORT}?sni=bing.com&insecure=1#${SERVER_IP}-${COUNTRY_CODE}"
  echo
}

function modify_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "未检测到配置文件，请先创建代理。"
    return
  fi

  # 读取当前端口和密码
  CURRENT_PORT=$(cat "$CONFIG_DIR/.listen_port" 2>/dev/null || echo "443")
  CURRENT_PASS=$(cat "$CONFIG_DIR/.password" 2>/dev/null || echo "")

  echo "当前监听端口: $CURRENT_PORT"
  while true; do
    read -rp "请输入新的监听端口（回车保持 $CURRENT_PORT）: " NEW_PORT
    NEW_PORT=${NEW_PORT:-$CURRENT_PORT}
    if [[ $NEW_PORT =~ ^[0-9]+$ ]] && (( NEW_PORT>0 && NEW_PORT<65536 )); then
      break
    else
      echo "端口输入不合法，请输入 1-65535 之间的数字"
    fi
  done

  echo "当前混淆密码: $CURRENT_PASS"
  while true; do
    read -rp "请输入新的混淆密码（回车保持当前密码）: " NEW_PASS
    NEW_PASS=${NEW_PASS:-$CURRENT_PASS}
    if [[ -n "$NEW_PASS" ]]; then
      break
    else
      echo "密码不能为空，请重新输入。"
    fi
  done

  # 修改配置文件
  sed -i "s/^listen: :.*/listen: :$NEW_PORT/" "$CONFIG_FILE"
  sed -i "s/^\(\s*password:\s*\).*$/\1$NEW_PASS/" "$CONFIG_FILE"

  # 保存新的端口和密码
  echo "$NEW_PORT" > "$CONFIG_DIR/.listen_port"
  echo "$NEW_PASS" > "$CONFIG_DIR/.password"

  echo "修改配置完成，正在重启 hysteria 服务..."

  pkill hysteria 2>/dev/null || true
  nohup "$INSTALL_PATH" server --config "$CONFIG_FILE" > "$LOG_PATH" 2>&1 &
  sleep 1

  echo "hysteria 已重启，监听端口: $NEW_PORT"
}

function uninstall_hysteria() {
  echo "停止 hysteria 服务..."
  pkill hysteria 2>/dev/null || echo "hysteria 服务未运行或已停止"

  echo "删除 hysteria 程序文件 $INSTALL_PATH"
  rm -f "$INSTALL_PATH"

  echo "删除配置目录 $CONFIG_DIR"
  rm -rf "$CONFIG_DIR"

  echo "删除日志文件 $LOG_PATH"
  rm -f "$LOG_PATH"

  echo "删除管理面板脚本自身：$THIS_SCRIPT"
  rm -f "$THIS_SCRIPT" && echo "面板脚本已删除。"

  echo "卸载完成。"
}

function main_menu() {
  while true; do
    echo "==================================="
    echo "        Hysteria 管理面板"
    echo "==================================="
    echo "1) 创建并启动 hy2 代理"
    echo "2) 修改 hy2 配置（端口和密码）"
    echo "3) 查看配置"
    echo "4) 删除 hy2 及面板脚本"
    echo "5) 退出"
    read -rp "请选择操作 [1-5]: " choice
    case $choice in
      1) install_hysteria ;;
      2) modify_config ;;
      3) show_client_config ;;
      4)
        read -rp "确认删除 hysteria 程序、配置及本脚本？(y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
          uninstall_hysteria
          exit 0
        else
          echo "取消删除。" 
        fi
      ;;
      5)
        echo "退出。"
        exit 0
      ;;
      *)
        echo "无效输入，请重新选择。"
      ;;
    esac
    echo
  done
}

main_menu
