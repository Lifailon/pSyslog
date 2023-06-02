# pSyslog

Syslog Server and Client based on **.NET Class System.Net.Sockets** to Background Job mode.

💡 **Development stage**

### 📚 Sources
Documentation used: **[metanit.com](https://metanit.com/sharp/net/3.1.php)** \
Source code refactoring syslog server: **[spiderip.com](https://spiderip.com/blog/2018/07/syslog)** \
Source udp client: **[cloudbrothers.info](https://cloudbrothers.info/en/test-udp-connection-powershell/)**

### 🚀 Install Module

For install or update module from the GitHub repository (used the script **[Deploy-pSyslog.ps1](https://github.com/Lifailon/pSyslog/blob/rsa/Module/Deploy-pSyslog.ps1)**) **use the command in the powershell console**:
```
Invoke-Expression(New-Object Net.WebClient).DownloadString("https://raw.githubusercontent.com/Lifailon/pSyslog/rsa/Module/Deploy-pSyslog.ps1")
```
**Supported PSVersion:** 5.1 and 7.3

Import module and get command list:
```
PS C:\Users\Lifailon> Import-Module pSyslog
PS C:\Users\Lifailon> Get-Command -Module pSyslog

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Get-pSyslog                                        0.4        pSyslog
Function        Send-pSyslog                                       0.4        pSyslog
Function        Show-pSyslog                                       0.4        pSyslog
Function        Start-pSyslog                                      0.4        pSyslog
Function        Stop-pSyslog                                       0.4        pSyslog
```

### 📫 pSyslog Server
```
PS C:\Users\Lifailon> Start-pSyslog -Port 514
PS C:\Users\Lifailon> Get-pSyslog -Status | Format-List

Status    : Running
StartTime : 02.06.2023 17:44:53
StopTime  :

PS C:\Users\Lifailon> Get-pSyslog

PS C:\Users\Lifailon> Get-pSyslog
02-06-2023 17:44:57 0.0.0.0 Informational Jun  2 17:44:56 zabbix-01 multipathd[783]: sda: add missing path
02-06-2023 17:44:57 192.168.3.102 Informational Jun  2 17:44:56 zabbix-01 multipathd[783]: sda: failed to get udev uid: Invalid argument
02-06-2023 17:44:57 192.168.3.102 Informational Jun  2 17:44:56 zabbix-01 multipathd[783]: sda: failed to get sysfs uid: Invalid argument
02-06-2023 17:44:57 192.168.3.102 Informational Jun  2 17:44:56 zabbix-01 multipathd[783]: sda: failed to get sgio uid: No such file or directory
02-06-2023 17:44:58 192.168.3.102 Warning Jun  2 17:44:56 zabbix-01 systemd-resolved[938]: Using degraded feature set (UDP) for DNS server 192.168.3.101.
02-06-2023 17:45:01 192.168.3.102 Warning Jun  2 17:44:59 zabbix-01 systemd-resolved[938]: Using degraded feature set (TCP) for DNS server 192.168.3.101.
...

PS C:\Users\Lifailon> Stop-pSyslog
PS C:\Users\Lifailon> Get-pSyslog -Status | Format-List

Status    : Stopped
StartTime : 02.06.2023 17:44:53
StopTime  : 02.06.2023 17:57:59
```

### 📧 pSyslog Client
```
Send-pSyslog -Message "Test message" -Server 192.168.3.99 -PortServer 514 -PortClient 55514
```
**Or use pipeline:**
```
"Status $((Get-Service -Name winrm).Name) - $((Get-Service -Name winrm).Status)" | Send-pSyslog -Server 192.168.3.99
```

### 📊 Out logfile to Object for collecting metrics
```
PS C:\Users\Lifailon> Show-pSyslog | Format-Table

TimeServer           IPAddress      HostName   Type           TimeClient      Service                Message
----------           ---------      --------   ----           ----------      -------                -------
02-06-2023 14:46:18  192.168.3.102  zabbix-01  Informational  2 Jun 14:46:16  multipathd[783]        sda: add missing path
02-06-2023 14:46:18  192.168.3.102  zabbix-01  Informational  2 Jun 14:46:16  multipathd[783]        sda: failed to get udev uid: Invalid argument
02-06-2023 14:46:18  192.168.3.102  zabbix-01  Informational  2 Jun 14:46:16  multipathd[783]        sda: failed to get sysfs uid: Invalid argument
02-06-2023 14:46:18  192.168.3.102  zabbix-01  Informational  2 Jun 14:46:16  multipathd[783]        sda: failed to get sgio uid: No such file or directory
02-06-2023 14:46:18  192.168.3.102  zabbix-01  Warning        2 Jun 14:46:17  systemd-resolved[938]  Using degraded feature set (UDP) for DNS server 192.168.3.101.
02-06-2023 14:46:21  192.168.3.102  zabbix-01  Warning        2 Jun 14:46:20  systemd-resolved[938]  Using degraded feature set (TCP) for DNS server 192.168.3.101.

PS C:\Users\Lifailon> Show-pSyslog -Type Warning | Format-Table

TimeServer          IPAddress     HostName  Type    TimeClient     Service               Message
----------          ---------     --------  ----    ----------     -------               -------
02-06-2023 14:46:06 0.0.0.0       zabbix-01 Warning 2 Jun 14:46:05 systemd-resolved[938] Using degraded feature set (UDP) for DNS server 192.168.3.101.
02-06-2023 14:46:09 192.168.3.102 zabbix-01 Warning 2 Jun 14:46:08 systemd-resolved[938] Using degraded feature set (TCP) for DNS server 192.168.3.101.
02-06-2023 14:46:18 192.168.3.102 zabbix-01 Warning 2 Jun 14:46:17 systemd-resolved[938] Using degraded feature set (UDP) for DNS server 192.168.3.101.
02-06-2023 14:46:21 192.168.3.102 zabbix-01 Warning 2 Jun 14:46:20 systemd-resolved[938] Using degraded feature set (TCP) for DNS server 192.168.3.101.

PS C:\Users\Lifailon> Show-pSyslog -Type Informational -Count
1253
PS C:\Users\Lifailon> Show-pSyslog -Type Warning -Count
251
PS C:\Users\Lifailon> Show-pSyslog -Type Unknown -Count
8
```

`Show-pSyslog | Out-GridView`

### 🎉 Example output console

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/0.3-Reception-from-pServer.jpg)

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/0.3-Ubuntu-Tail-Local-Syslog.jpg)

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/0.4-Reception-Unknown-Message.jpg)

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/0.4-Send-to-rSyslog-Server.jpg)

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/0.4-Send-to-Visual-Syslog-Server.jpg)
