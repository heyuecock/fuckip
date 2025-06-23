#!/bin/bash
set -e

INSTALL_DIR="/usr/local/nezha"
BIN_PATH="${INSTALL_DIR}/nezha-agent"
LOG_PATH="${INSTALL_DIR}/nezha-agent.log"
CONFIG_FILE="${INSTALL_DIR}/config.conf"
THIS_SCRIPT="$(readlink -f "$0")"

# 从 GitHub 获取最新版本号 v1 分支用
function fetch_latest_version() {
  echo "正在获取最新版本号..."
  local latest_version
  latest_version=$(curl -s "https://api.github.com/repos/nezhahq/agent/releases/latest" | grep '"tag_name":' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
  if [[ -z "$latest_version" ]]; then
    echo "获取最新版本失败，使用默认版本 v0.20.5"
    latest_version="v0.20.5"
  fi
  echo "获取到最新版本：$latest_version"
  echo "$latest_version"
}

function save_config() {
  cat > "$CONFIG_FILE" <<-EOF
SERVER="$SERVER"
PASSWORD="$PASSWORD"
USE_TLS="$USE_TLS"
VERSION="$VERSION"
EOF
}

function load_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
  else
    SERVER=""
    PASSWORD=""
    USE_TLS="false"
    VERSION="v0.20.5"
  fi
}

function download_and_install() {
  # 版本选择
  echo "请选择安装哪吒 Agent 版本："
  echo "1) v0.20.5 (v0 分支稳定版本)"
  echo "2) 最新版本 (v1 分支)"
  while true; do
    read -rp "请输入数字选择版本 [1-2]: " ver_choice
    case "$ver_choice" in
      1)
        VERSION="v0.20.5"
        break
        ;;
      2)
        VERSION=$(fetch_latest_version)
        break
        ;;
      *)
        echo "输入无效，请输入 1 或 2 。"
        ;;
    esac
  done

  read -rp "请输入哪吒服务端地址（格式 域名:端口）: " SERVER
  while [[ -z "$SERVER" ]]; do
    echo "服务端地址不能为空。"
    read -rp "请输入哪吒服务端地址（格式 域名:端口）: " SERVER
  done

  read -rp "请输入密钥: " PASSWORD
  while [[ -z "$PASSWORD" ]]; do
    echo "密钥不能为空。"
    read -rp "请输入密钥: " PASSWORD
  done

  while true; do
    read -rp "是否启用 TLS？(true/false，默认 false): " tls_input
    tls_input=${tls_input:-false}
    if [[ "$tls_input" == "true" || "$tls_input" == "false" ]]; then
      USE_TLS="$tls_input"
      break
    else
      echo "请输入 true 或 false"
    fi
  done

  save_config

  echo "安装目录: $INSTALL_DIR"
  mkdir -p "$INSTALL_DIR"

  # 获取系统架构
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64)
      ARCH="linux_amd64"
      ;;
    aarch64|arm64)
      ARCH="linux_arm64"
      ;;
    armv7l)
      ARCH="linux_armv7"
      ;;
    *)
      echo "未知架构 $ARCH，默认使用 linux_amd64"
      ARCH="linux_amd64"
      ;;
  esac

  FILENAME="nezha-agent_${ARCH}.zip"
  DOWNLOAD_URL="https://github.com/nezhahq/agent/releases/download/${VERSION}/${FILENAME}"

  echo "下载 nezha-agent 版本 $VERSION，架构 $ARCH..."
  curl -L -o "${INSTALL_DIR}/${FILENAME}" "$DOWNLOAD_URL"

  echo "解压..."
  unzip -o "${INSTALL_DIR}/${FILENAME}" -d "${INSTALL_DIR}"

  echo "赋予执行权限..."
  chmod +x "$BIN_PATH"

  echo "启动 nezha-agent..."
  killall nezha-agent 2>/dev/null || true

  TLS_ARG=""
  if [[ "$USE_TLS" == "true" ]]; then
    TLS_ARG="--tls"
  fi

  nohup "$BIN_PATH" -s "$SERVER" -p "$PASSWORD" $TLS_ARG > "$LOG_PATH" 2>&1 &

  echo "安装并启动完成，日志路径：$LOG_PATH"
}

# 以下函数和之前示例一致
function modify_config() {
  load_config
  echo "当前配置："
  echo "服务端地址: $SERVER"
  echo "密钥: $PASSWORD"
  echo "启用 TLS: $USE_TLS"
  echo "版本: $VERSION"
  echo

  read -rp "请输入新的服务端地址（留空保持不变）: " new_server
  if [[ -n "$new_server" ]]; then
    SERVER="$new_server"
  fi

  read -rp "请输入新的密钥（留空保持不变）: " new_password
  if [[ -n "$new_password" ]]; then
    PASSWORD="$new_password"
  fi

  while true; do
    read -rp "是否启用 TLS？(true/false，留空保持不变): " tls_input
    if [[ -z "$tls_input" ]]; then
      break
    elif [[ "$tls_input" == "true" || "$tls_input" == "false" ]]; then
      USE_TLS="$tls_input"
      break
    else
      echo "请输入 true 或 false，或直接回车留空"
    fi
  done

  while true; do
    echo "当前版本: $VERSION"
    echo "是否更改版本？请选择："
    echo "1) v0.20.5 (v0 分支稳定版本)"
    echo "2) 最新版本 (v1 分支)"
    echo "3) 保持不变"
    read -rp "请输入数字选择版本 [1-3]: " ver_choice

    case "$ver_choice" in
      1)
        VERSION="v0.20.5"
        break
        ;;
      2)
        VERSION=$(fetch_latest_version)
        break
        ;;
      3|"" )
        # 保持不变
        break
        ;;
      *)
        echo "无效输入，请输入 1、2 或 3。"
        ;;
    esac
  done

  save_config

  echo "修改完成，重新安装并启动 nezha-agent..."
  uninstall_agent --no-self-remove
  download_and_install --no-prompt
}

function show_config() {
  load_config
  echo "当前哪吒 Agent 配置："
  echo "服务端地址: $SERVER"
  echo "密钥: $PASSWORD"
  echo "启用 TLS: $USE_TLS"
  echo "版本: $VERSION"
  echo "程序路径: $BIN_PATH"
  echo "日志路径: $LOG_PATH"
}

function uninstall_agent() {
  local self_remove="yes"
  if [[ "$1" == "--no-self-remove" ]]; then
    self_remove="no"
  fi

  echo "停止 nezha-agent 进程..."
  killall nezha-agent 2>/dev/null || echo "进程未运行或已停止"

  echo "删除程序文件和安装目录..."
  rm -rf "$INSTALL_DIR"

  if [[ "$self_remove" == "yes" ]]; then
    echo "删除管理脚本自身：$THIS_SCRIPT"
    rm -f "$THIS_SCRIPT" && echo "管理脚本已删除。"
  fi

  echo "卸载完成。"
}

function start_agent() {
  load_config

  if [[ ! -x "$BIN_PATH" ]]; then
    echo "nezha-agent 未安装，请先执行安装。"
    return 1
  fi

  TLS_ARG=""
  if [[ "$USE_TLS" == "true" ]]; then
    TLS_ARG="--tls"
  fi

  echo "启动 nezha-agent..."
  killall nezha-agent 2>/dev/null || true

  nohup "$BIN_PATH" -s "$SERVER" -p "$PASSWORD" $TLS_ARG > "$LOG_PATH" 2>&1 &

  sleep 1
  echo "nezha-agent 已启动，日志: $LOG_PATH"
}

function main_menu() {
  while true; do
    echo "==================================="
    echo "          哪吒 Agent 管理面板        "
    echo "==================================="
    echo "1) 安装/重装 nezha-agent"
    echo "2) 修改配置并重新安装"
    echo "3) 查看当前配置"
    echo "4) 卸载 nezha-agent 及管理脚本"
    echo "5) 退出"
    read -rp "请选择操作 [1-5]: " choice

    case $choice in
      1) download_and_install ;;
      2) modify_config ;;
      3) show_config ;;
      4)
        read -rp "确认卸载并删除程序及管理脚本？(y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
          uninstall_agent
          exit 0
        else
          echo "取消卸载。"
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
