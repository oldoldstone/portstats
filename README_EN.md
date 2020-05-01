# Portstats: A Tool for Monitoring Port Traffic 

## [中文说明](https://github.com/oldoldstone/portstats/blob/master/README.md)

## Portstats

## Description

Portstats is a simple shell script for monitoring the port traffic using iptables.
 
## Features

* daily and monthly report 

## Installation
```bash
git clone  https://github.com/oldoldstone/portstats
cd portstats
chmod +x ./portstats.sh
./portstats.sh install
```
 
The sript will add a hourly crontab task, so there is no need to run it manually. You can view the daily and monthly log for the traffic statistics for every port.

### Usage

argument: install|uninstall|run|config

- install

  set up running environment: including iptables chain, cron task, ports and log folder configuration.
  
- uninstall
  
remove  iptables chain and cron task.

- run

run the script to cout traffic immediately

- config

ports and log location reconfiguration
 
### Log formats
- Daily log(20xx-xx-xx.log)
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
- Monthly log(20xx-xx-sum.log)
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
-- **Input, Output: Network traffic of last period（Auto format） **

-- inBytes, outBytes: Network traffic of last period（In Bytes）

-- TotalIn, TotalOut: Total network traffic of the port, however, it will be reset when new day begins or ports change, just for network traffic calculation.