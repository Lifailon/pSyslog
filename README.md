# pSyslog

Syslog Server and Client based on **.NET Class System.Net.Sockets** to Background Job mode.

💡 **Development stage**

### 📚 Sources
Documentation used (udp socket): **[metanit.com](https://metanit.com/sharp/net/3.1.php)** \
Documentation used (syslog message): **[devconnected.com](https://devconnected.com/syslog-the-complete-system-administrator-guide/)** \
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

CommandType     Name                     Version    Source
-----------     ----                     -------    ------
Function        Get-pSyslog              0.5        pSyslog
Function        Send-pSyslog             0.5        pSyslog
Function        Show-pSyslog             0.5        pSyslog
Function        Start-pSyslog            0.5        pSyslog
Function        Stop-pSyslog             0.5        pSyslog
```

### 📫 pSyslog Server
```
PS C:\Users\Lifailon> Start-pSyslog -Port 514
PS C:\Users\Lifailon>  Get-pSyslog -Status | Format-List

Status    : Running
StartTime : 06.06.2023 1:09:47
StopTime  :

PS C:\Users\Lifailon> Get-pSyslog

PS C:\Users\Lifailon> Get-pSyslog
Jun 6 01:11:01 zabbix-01        Informational authpriv CRON[3052]:               pam_unix(cron:session): session opened for user root by (uid=0)
Jun 6 01:11:01 zabbix-01        Informational cron     CRON[3053]:               (root) CMD (date >> /dump/zabbix/cron-test-date.txt)
Jun 6 01:11:01 zabbix-01        Informational authpriv CRON[3052]:               pam_unix(cron:session): session closed for user root
Jun 6 01:11:03 zabbix-01        Informational daemon   multipathd[784]:          sda: add missing path
Jun 6 01:11:03 zabbix-01        Informational daemon   multipathd[784]:          sda: failed to get udev uid: Invalid argument
Jun 6 01:11:03 zabbix-01        Informational daemon   multipathd[784]:          sda: failed to get sysfs uid: Invalid argument
Jun 6 01:11:03 zabbix-01        Informational daemon   multipathd[784]:          sda: failed to get sgio uid: No such file or directory
Jun 6 01:11:01 plex-01          Informational user     Service[WinRM]            Running
...

PS C:\Users\Lifailon> Stop-pSyslog
PS C:\Users\Lifailon> Get-pSyslog -Status | Format-List

Status    : Stopped
StartTime : 06.06.2023 1:09:47
StopTime  : 06.06.2023 1:13:43
```

### 📧 pSyslog Client
```
Send-pSyslog -Content "Test" -Server 192.168.3.99
Send-pSyslog -Message "Test" -Server 192.168.3.99 -Type Informational -PortServer 514 -PortClient 55514
```
**Or use pipeline:**
```
(Get-Service -Name WinRM).Status | Send-pSyslog -Server 192.168.3.99 -Tag Service[WinRM]
```

### 📊 Out logfile to Object for collecting metrics
```
PS C:\Users\Lifailon> Show-pSyslog | Format-Table

TimeServer          IPAddress     HostName  Type          TimeClient     Tag                              Message
----------          ---------     --------  ----          ----------     ---                              -------
...
06-06-2023 01:21:59 192.168.3.102 zabbix-01 Informational 6 Jun 01:21:58 systemd[3484]                    Listening on REST API socket for snapd user session agent.
06-06-2023 01:21:59 192.168.3.102 zabbix-01 Informational 6 Jun 01:21:58 systemd[3484]                    Listening on D-Bus User Message Bus Socket.
06-06-2023 01:21:59 192.168.3.102 zabbix-01 Informational 6 Jun 01:21:58 systemd[3484]                    Reached target Sockets.
06-06-2023 01:21:59 192.168.3.102 zabbix-01 Informational 6 Jun 01:21:58 systemd[3484]                    Reached target Basic System.
06-06-2023 01:21:59 192.168.3.102 zabbix-01 Informational 6 Jun 01:21:58 systemd[3484]                    Reached target Main User Target.
06-06-2023 01:21:59 192.168.3.102 zabbix-01 Informational 6 Jun 01:21:58 systemd[3484]                    Startup finished in 68ms.
06-06-2023 01:21:59 192.168.3.102 zabbix-01 Informational 6 Jun 01:21:58 systemd[1]                       Started User Manager for UID 1000.
06-06-2023 01:21:59 192.168.3.102 zabbix-01 Informational 6 Jun 01:21:58 systemd[1]                       Started Session 52 of user lifailon.
06-06-2023 01:21:59 192.168.3.102 zabbix-01 Informational 6 Jun 01:21:59 multipathd[784]                  sda: add missing path
06-06-2023 01:21:59 192.168.3.102 zabbix-01 Informational 6 Jun 01:21:59 multipathd[784]                  sda: failed to get udev uid: Invalid argument
06-06-2023 01:21:59 192.168.3.102 zabbix-01 Informational 6 Jun 01:21:59 multipathd[784]                  sda: failed to get sysfs uid: Invalid argument
06-06-2023 01:21:59 192.168.3.102 zabbix-01 Informational 6 Jun 01:21:59 multipathd[784]                  sda: failed to get sgio uid: No such file or directory
...

Example logfile system reboot: 

PS C:\Users\Lifailon> Show-pSyslog -Type Informational -Count
1253
PS C:\Users\Lifailon> Show-pSyslog -Type Warning -Count
251
PS C:\Users\Lifailon> Show-pSyslog -Type Unknown -Count
8
```

### 🔍 Search

`Show-pSyslog | Out-GridView`

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/Show-Out-GridView.jpg)

### 🎉 Example output console

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/Reception-Unknown-Message.jpg)

**Local syslog (using tail)**

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/Local-Syslog-Tail.jpg)

### 💬 Sending use cmdlet powershell Send-pSyslog to rSyslog

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/Send-to-rSyslog-Server.jpg)

**Sending to Visual Syslog Server**

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/Send-to-Visual-Syslog-Server.jpg)
