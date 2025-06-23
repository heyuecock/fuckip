#!/bin/bash
set -e

# 配置参数（可根据需要修改）
HY_BIN_URL="https://download.hysteria.network/app/latest/hysteria-linux-arm64"
INSTALL_PATH="/usr/local/bin/hysteria"
CONFIG_DIR="/etc/hysteria"
LOG_PATH="/var/log/hysteria.log"

echo "检测并安装依赖 curl wget openssl jq..."
if command -v apt-get &>/dev/null; then
    apt-get update
    apt-get install -y curl wget openssl jq
elif command -v yum &>/dev/null; then
    yum install -y curl wget openssl jq
else
    echo "未检测到 apt-get/yum，请手动安装 curl wget openssl jq"
fi

echo "下载最新 hysteria 程序..."
curl -L -o "$INSTALL_PATH" "$HY_BIN_URL"
chmod +x "$INSTALL_PATH"

echo "创建配置目录: $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

echo "生成 EC 自签 TLS 证书（prime256v1）..."
EC_PARAM_FILE=$(mktemp)
openssl ecparam -name prime256v1 -out "$EC_PARAM_FILE"
openssl req -x509 -nodes -newkey ec:"$EC_PARAM_FILE" \
    -keyout "$CONFIG_DIR/server.key" -out "$CONFIG_DIR/server.crt" -days 36500 \
    -subj "/CN=bing.com"
rm -f "$EC_PARAM_FILE"

read -rp "监听端口 (默认 443): " LISTEN_PORT
LISTEN_PORT=${LISTEN_PORT:-443}

while true; do
    read -rp "混淆密码（必填）: " PASSWORD
    [[ -n "$PASSWORD" ]] && break
    echo "密码不能为空，请重新输入。"
done


# 生成新版 hysteria YAML 配置文件
cat > "$CONFIG_DIR/config.yaml" <<EOF
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


echo "启动 hysteria 服务端..."
nohup "$INSTALL_PATH" server --config "$CONFIG_DIR/config.yaml" > "$LOG_PATH" 2>&1 &

echo "hysteria 已后台启动，监听端口 $LISTEN_PORT"
echo "日志文件路径：$LOG_PATH"

# 获取服务器公网 IP 作为 SERVER_DOMAIN（如果你有域名，可以手动替换此变量）
SERVER_IP=$(curl -s https://ipinfo.io/ip)
SERVER_DOMAIN=$SERVER_IP  # 这里用 IP 代替域名

# 尝试获取国家代码，没有 jq 也用纯文本截取
COUNTRY_CODE=$(curl -s https://ipinfo.io/country | tr -d '\n')

echo
echo "🔗 Hysteria 客户端连接信息示例 (请根据客户端文档确认格式):"
echo "hy2://$PASSWORD@${SERVER_IP}:${LISTEN_PORT}?sni=bing.com&insecure=1#${SERVER_DOMAIN}-${COUNTRY_CODE}"
echo
