# pSyslog

[![GitHub Release](https://img.shields.io/github/v/release/Lifailon/pSyslog?display_name=release&logo=GitHub&label=GitHub&link=https%3A%2F%2Fgithub.com%2FLifailon%2FpSyslog%2F)](https://github.com/Lifailon/pSyslog)
[![NuGet Version](https://img.shields.io/nuget/v/pSyslog?logo=NuGet&label=NuGet&link=https%3A%2F%2Fwww.nuget.org%2Fpackages%2FpSyslog)](https://www.nuget.org/packages/pSyslog)
[![GitHub top language](https://img.shields.io/github/languages/top/Lifailon/pSyslog?logo=PowerShell&link=https%3A%2F%2Fgithub.com%2FPowerShell%2FPowerShell)](https://github.com/PowerShell/PowerShell)
[![GitHub License](https://img.shields.io/github/license/Lifailon/pSyslog?link=https%3A%2F%2Fgithub.com%2FLifailon%2FpSyslog%2Fblob%2Frsa%2FLICENSE)](https://github.com/Lifailon/pSyslog/blob/rsa/LICENSE)

Syslog Server/Client and UDP Relay based on **.NET Framework Class System.Net.Sockets** to Background Job mode.

- [📚 Sources](#-Sources)
- [🚀 Install](#-Install)
- [📭 Server](#-pSyslog-Server)
- [✉️ Client](#%EF%B8%8F-pSyslog-Client)
- [🔌 rSyslog ](#-rsyslog-compatibility)
- [🚧 Encryption](#-Encryption-Base64)
- [♻️ UDP Relay](#%EF%B8%8F-UDP-Relay)
- [📊 Metrics](#-Metrics)
- [🔍 Search](#-Search)
- [📑 Rotation](#-Rotation)
- [🐧 Linux Client](#-Linux-Client)

### 📚 Sources

Documentation used (udp socket): **[metanit.com](https://metanit.com/sharp/net/3.1.php)** \
Documentation used (syslog message): **[devconnected.com](https://devconnected.com/syslog-the-complete-system-administrator-guide/)** \
Source code refactoring syslog server: **[spiderip.com](https://spiderip.com/blog/2018/07/syslog)** \
Source udp client: **[cloudbrothers.info](https://cloudbrothers.info/en/test-udp-connection-powershell/)**

### 🚀 Install

Install module from [NuGet repository](https://www.nuget.org/packages/pSyslog):

```PowerShell
Install-Module pSyslog -Repository NuGet
```

💡 You must have a NuGet repository registered:

```PowerShell
Register-PSRepository -Name "NuGet" -SourceLocation "https://www.nuget.org/api/v2" -InstallationPolicy Trusted
```

Or used install or update module from the GitHub repository (used the script **[Deploy-pSyslog.ps1](https://github.com/Lifailon/pSyslog/blob/rsa/Module/Deploy-pSyslog.ps1)**) **use the command in the powershell console**:
```
Invoke-Expression(New-Object Net.WebClient).DownloadString("https://raw.githubusercontent.com/Lifailon/pSyslog/rsa/Module/Deploy-pSyslog.ps1")
```
**Supported PSVersion:** 5.1 and 7.3

**Import module and get command list:**
```
PS C:\Users\Lifailon> Import-Module pSyslog
PS C:\Users\Lifailon> Get-Command -Module pSyslog

CommandType     Name                     Version    Source
-----------     ----                     -------    ------
Function        Get-pSyslog              0.6        pSyslog
Function        Send-pSyslog             0.6        pSyslog
Function        Show-pSyslog             0.6        pSyslog
Function        Start-pSyslog            0.6        pSyslog
Function        Start-UDPRelay           0.6        pSyslog
Function        Stop-pSyslog             0.6        pSyslog
```

### 📭 pSyslog Server
```
PS C:\Users\Lifailon> Start-pSyslog -Port 514
PS C:\Users\Lifailon> Get-pSyslog -Status | Format-List

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

### ✉️ pSyslog Client
```
Send-pSyslog -Content "Test" -Server 192.168.3.99
Send-pSyslog -Content "Test" -Server 192.168.3.99 -Type Informational -PortServer 514 -PortClient 55514
```
![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/Send-pSyslog.jpg)


### 🔌 rSyslog compatibility
Use pipeline and sending to rSyslog server:
```
(Get-Service -Name WinRM).Status | Send-pSyslog -Server 192.168.3.102 -Tag Service[WinRM]
```
![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/Send-pSyslog-Rsyslog.jpg)

### 🚧 Encryption Base64
```
Send-pSyslog -Content "test" -Server 192.168.3.99 -PortServer 514
Send-pSyslog -Content "test" -Server 192.168.3.99 -PortServer 514 -Base64
```
**Wireshark filter:** `udp.dstport == 514 && ip.src == 192.168.3.100 && !icmp`

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/Encrypt-Base64.jpg)

### ♻️ UDP Relay

**Server** (192.168.3.102): `Start-pSyslog -Port 514` \
**Relay**  (192.168.3.99):  `Start-UDPRelay -inPort 515 -outIP 192.168.3.102 -outPort 514` \
**Client** (192.168.3.100): `Send-pSyslog -Server 192.168.3.99 -PortServer 515 -Content $(Get-Date)`

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/UDPRelay.jpg)

### 📊 Metrics
Out logfile to Object for collecting metrics
```
PS C:\Users\Lifailon> Show-pSyslog -Type Warning -Count
2917
PS C:\Users\Lifailon> Show-pSyslog -Type Alert -Count
36
PS C:\Users\Lifailon> Show-pSyslog -Type Critical -Count
5
PS C:\Users\Lifailon> Show-pSyslog -Type Error -Count
5
PS C:\Users\Lifailon> Show-pSyslog -Type Emergency -Count
0
PS C:\Users\Lifailon> Show-pSyslog -Type Informational -Count
15491
```

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/Show-pSyslog-Metrics.jpg)

### 🔍 Search

`Show-pSyslog | Out-GridView`

**Or view old journal by wildcard file name:**

`Show-pSyslog -LogFile 05-06 | Out-GridView`

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/Show-pSyslog-Out-GridView.jpg)

Example logfile system reboot: **[06-06-2023_reboot.log](https://github.com/Lifailon/pSyslog/blob/rsa/Example/06-06-2023_reboot.log)**

### 📑 Rotation
Logfile rotation and show all log files in 24 hours:
```
Start-pSyslog -RotationSize 500
Show-pSyslog -Count
Show-pSyslog -Count -LogFile 10-06
```
![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/Rotation-Logfile.jpg)

### 🐧 Linux Client:

**Example output local syslog (using tail):**

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/Syslog-Local-Tail.jpg)


**Example pSyslog server output to console powershell:**

![Image alt](https://github.com/Lifailon/pSyslog/blob/rsa/Screen/pSyslog-Console.jpg)
