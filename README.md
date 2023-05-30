# pSyslog

### 📚 Sources
Server based on **.NET Class System.Net.Sockets** \
Source code refactoring syslog server: https://spiderip.com/blog/2018/07/syslog \
Documentation used: https://metanit.com/sharp/net/3.1.php \
Compared to the source code: recycled output and added socket closing (version 0.1)

⌛ Plan to add the client part in the next versions for module and User Interface for server part.

### 🚀 Import and Get Module
```
PS C:\Users\Lifailon> Import-Module $home\Desktop\pSyslog-0.2.psm1
PS C:\Users\Lifailon> Get-Command -Module pSyslog-0.2

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Get-pSyslog                                        0.0        pSyslog-0.2
Function        Show-pSyslog                                       0.0        pSyslog-0.2
Function        Start-pSyslog                                      0.0        pSyslog-0.2
Function        Stop-pSyslog                                       0.0        pSyslog-0.2
```

### 🔔 Management pSyslog Server (BackgroundJob mode)
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

### 📊 Out log file to Object for collecting metrics
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

### 🎉 Example

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/0.1-PS7.jpg)

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/0.1-PS5.jpg)
