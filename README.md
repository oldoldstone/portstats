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
 
### 日志格式
- 日报告(20xx-xx-xx.log)
```bash
    Time  Port    Input   Output    TotalIn   TotalOut    inBytes   outBytes
00:00:01 12345        0        0          0          0          0          0
00:00:01 23456        0        0          0          0          0          0 
01:00:01 12345      58K     150K      57840     149844      57840     149844
01:00:01 23456        0        0          0          0          0          0
01:00:01 12345     1.8M     2.5M    1765882    2426923    1765882    2426923
02:00:01 12345        0        0          0          0          0          0
...
Total    12345     5.4M      22M    5335729   21853916
Total    23456     308K     767K     307141     766084 
```
- 月报告(20xx-xx-sum.log)
```bash
      Date  Port    Input   Output    inBytes   outBytes
2020-04-28 12345      12M     812M   11967270  811511352
2020-04-28 23456        0        0          0          0
2020-04-29 12345      13M     102M   12262100  101329488
2020-04-29 23456        0        0          0          0
2020-04-30 12345      79M     4.5G   78663889 4439889135
2020-04-30 23456        0        0          0          0

Total      12345     103M     5.4G  102893259 5352729975
Total      23456        0        0          0          0

```
-- **Input, Output: 代表当前时段流量（自动单位） **

-- inBytes, outBytes: 代表当前时段流量（字节单位）

-- TotalIn, TotalOut: 端口的总流量，仅用来计算，每天开始或者端口改变时会清0。