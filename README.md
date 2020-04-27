# 端口流量统计脚本

## [Readme in English](https://github.com/oldoldstone/portstats/blob/master/README_EN.md)

## Portstats

基于iptables的端口流量统计脚本。
 
## Features

* 任意端口统计，可随时更换，并保留以前流量数据
* 日志分端口统计，提供每日和每月报告
* 自定义iptables链，不影响其他服务

## 安装
```bash
git clone  https://github.com/oldoldstone/portstats
cd portstats
chmod +x ./portstats.sh
./portstats.sh install
```
 
脚本需要主机安装cron，每小时执行一次，无需手动运行

### 使用

argument: install|uninstall|run|config

- install

  初始化运行环境，添加iptables链和cron定时任务，端口的初始配置（多个端口以空格隔开），日志存放路径。
  
- uninstall
  
移除iptables链和cron定时任务

- run

手动运行统计，可用于测试。

- config

重新配置需要监测的端口和日志存放路径。
 
### 截屏
 