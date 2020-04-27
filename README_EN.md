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
 
### Screnshot
 