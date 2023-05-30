# PSyslog
### Import and Get Module
```
PS C:\Users\Lifailon> Import-Module $home\Desktop\pSyslog-0.2.psm1
PS C:\Users\Lifailon> (Get-Module pSyslog-0.2).ExportedCommands.Keys

Get-pSyslog
Show-pSyslog
Start-pSyslog
Stop-pSyslog
```
### Managment pSyslog Server
```
PS C:\Users\Lifailon> Start-pSyslog -Port 514
PS C:\Users\Lifailon> Get-pSyslog -Status | fl

Status    : Running
StartTime : 30.05.2023 17:26:33
StopTime  :

PS C:\Users\Lifailon> Get-pSyslog

30-05-2023 17:26:37 0.0.0.0 Informational May 30 17:26:31 zabbix-01 multipathd[784]: sda: add missing path
30-05-2023 17:26:37 192.168.3.102 Informational May 30 17:26:31 zabbix-01 multipathd[784]: sda: failed to get udev uid: Invalid argument
30-05-2023 17:26:37 192.168.3.102 Informational May 30 17:26:31 zabbix-01 multipathd[784]: sda: failed to get sysfs uid: Invalid argument
30-05-2023 17:26:37 192.168.3.102 Informational May 30 17:26:31 zabbix-01 multipathd[784]: sda: failed to get sgio uid: No such file or directory
30-05-2023 17:26:39 192.168.3.102 Warning May 30 17:26:33 zabbix-01 systemd-resolved[938]: Using degraded feature set (UDP) for DNS server 192.168.3.101.
...

PS C:\Users\Lifailon> Stop-pSyslog
PS C:\Users\Lifailon> Get-pSyslog -Status | fl

Status    : Stopped
StartTime : 30.05.2023 17:26:33
StopTime  : 30.05.2023 17:28:21
```
### Out log file to Object for collecting metrics
```
PS C:\Users\Lifailon> Show-PSyslog -Informational
3363
PS C:\Users\Lifailon> Show-PSyslog -Warning
675
PS C:\Users\Lifailon> Show-PSyslog -Error
0
PS C:\Users\Lifailon> Show-PSyslog -Critical
0

PS C:\Users\Lifailon> Show-PSyslog | ft

TimeServer          IPAddress     HostName  Type          TimeClient      Service               Message
----------          ---------     --------  ----          ----------      -------               -------
30-05-2023 12:20:13 192.168.3.102 zabbix-01 Warning       30 May 12:20:07 systemd-resolved[938] Using degraded feature set (UDP) for DNS server 192.168.3.101.
30-05-2023 12:20:16 192.168.3.102 zabbix-01 Warning       30 May 12:20:11 systemd-resolved[938] Using degraded feature set (TCP) for DNS server 192.168.3.101.
30-05-2023 12:20:28 0.0.0.0       zabbix-01 Warning       30 May 12:20:23 systemd-resolved[938] Using degraded feature set (TCP) for DNS server 192.168.3.101.
30-05-2023 12:20:33 192.168.3.102 zabbix-01 Informational 30 May 12:20:27 multipathd[784]       sda: add missing path
30-05-2023 12:20:33 192.168.3.102 zabbix-01 Informational 30 May 12:20:27 multipathd[784]       sda: failed to get udev uid: Invalid argument
30-05-2023 12:20:33 192.168.3.102 zabbix-01 Informational 30 May 12:20:27 multipathd[784]       sda: failed to get sysfs uid: Invalid argument
30-05-2023 12:20:33 192.168.3.102 zabbix-01 Informational 30 May 12:20:27 multipathd[784]       sda: failed to get sgio uid: No such file or directory
30-05-2023 12:20:38 192.168.3.102 zabbix-01 Warning       30 May 12:20:32 systemd-resolved[938] Using degraded feature set (UDP) for DNS server 192.168.3.101.
30-05-2023 12:20:38 192.168.3.102 zabbix-01 Informational 30 May 12:20:32 multipathd[784]       sda: add missing path
```
