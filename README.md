hy2脚本使用方法
sudo curl -o /usr/local/bin/hy2 -L https://raw.githubusercontent.com/heyuecock/fuckip/refs/heads/main/hy2.sh
sudo chmod +x /usr/local/bin/hy2

哪吒agent脚本使用方法
sudo curl -o /usr/local/bin/agent -L https://raw.githubusercontent.com/heyuecock/fuckip/refs/heads/main/agent.sh
sudo chmod +x /usr/local/bin/agent

# 哪吒 Agent 管理脚本（agent.sh）
这是一个用于安装、配置、管理哪吒监控 Agent 的脚本管理面板，支持安装 v0 稳定版本和最新 v1 版本，方便快速部署和维护。
---
## 快速安装
```bash
sudo curl -o /usr/local/bin/agent -L https://raw.githubusercontent.com/heyuecock/fuckip/refs/heads/main/agent.sh
sudo chmod +x /usr/local/bin/agent
```
执行以上命令即可下载并授权脚本到 /usr/local/bin/agent。

---
## 使用说明
执行脚本启动交互菜单：
```bash
sudo agent
```
可根据提示选择：
安装/重装 nezha-agent
修改配置并重新安装
查看当前配置
卸载 nezha-agent 及本管理脚本
退出

---
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
## 备注
本脚本默认安装路径为 /usr/local/nezha
日志文件默认保存于 /usr/local/nezha/nezha-agent.log
建议以 sudo 权限运行，以保证对 /usr/local/bin 和 /usr/local/nezha 目录的访问权限
