# 哪吒 Agent 管理脚本（agent.sh）
这是一个用于安装、配置、管理哪吒监控 Agent 的脚本管理面板，支持安装 v0 稳定版本和最新 v1 版本，方便快速部署和维护。
## 快速安装
```bash
sudo curl -o /usr/local/bin/agent -L https://raw.githubusercontent.com/heyuecock/fuckip/refs/heads/main/agent.sh
sudo chmod +x /usr/local/bin/agent
```
执行以上命令即可下载并授权脚本到 /usr/local/bin/agent。

## 使用说明
执行脚本启动交互菜单：
```bash
agent
```
可根据提示选择：
安装/重装 nezha-agent
修改配置并重新安装
查看当前配置
卸载 nezha-agent 及本管理脚本
退出

## 功能介绍
### 安装
支持选择安装 v0 稳定版本（v0.20.5）或最新 v1 版本（自动获取最新版本号）
### 配置
动态设置服务端地址(Server)、密钥(Password)、是否启用 TLS
### 查看配置
展示当前已安装的基本配置及版本信息
### 卸载
停止 Agent，删除安装文件及本脚本

---

# hy2 - Hysteria 代理微型管理面板

## 简介
`hy2` 是一款基于 Hysteria 的轻量级代理管理脚本，可快速创建、修改及删除代理配置，支持 Debian、Ubuntu、Alpine 等主流 Linux 发行版。

## 快速安装

使用以下命令一键下载安装并添加执行权限：

```bash
sudo curl -o /usr/local/bin/hy2 -L https://raw.githubusercontent.com/heyuecock/fuckip/refs/heads/main/hy2.sh
sudo chmod +x /usr/local/bin/hy2
```
安装完成后，即可在终端输入 hy2 启动管理面板。

## 功能说明
创建并启动 hy2 代理

一键生成自签证书，配置端口与混淆密码，启动 Hysteria 服务。

修改 hy2 配置（端口和密码）

修改监听端口和混淆密码，并自动重启服务。

查看配置

显示客户端连接字符串，方便复制使用。

删除 hy2 及面板脚本

停止服务，删除程序、配置、日志和安装脚本。

## 系统支持
Debian / Ubuntu (使用 apt-get 安装依赖)
Alpine Linux (使用 apk 安装依赖)
CentOS / Fedora (使用 yum 安装依赖)

## 使用说明
运行安装脚本后，执行：

```bash
hy2
```
选择对应数字操作菜单即可创建/修改/查看或删除代理。

创建代理时，需要输入监听端口（默认 443）和混淆密码。

修改配置时也可更改端口和密码。
## 卸载
选择删除操作后脚本会自动停止服务，清理配置及日志，并删除自身。

如果脚本意外删除，手动删除文件：

```bash
sudo rm -f /usr/local/bin/hy2
sudo rm -rf /etc/hysteria
sudo rm -f /var/log/hysteria.log
pkill hysteria || true
```
