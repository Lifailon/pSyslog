### Version 0.4
### Source module: https://github.com/Lifailon/pSyslog
### Source code refactoring syslog server: https://spiderip.com/blog/2018/07/syslog
### Documentation used: https://metanit.com/sharp/net/3.1.php
### Source udp client: https://cloudbrothers.info/en/test-udp-connection-powershell/
### Example:
### Import-Module Start-pSyslog-0.2.psm1
### Start-pSyslog -Port 514
### Stop-pSyslog
### Get-pSyslog
### Get-pSyslog -Status
### Show-pSyslog | Format-Table
### Show-pSyslog | Out-GridView
### Show-pSyslog -Type Warning | Format-Table
### Show-pSyslog -Type Informational -Count
### "Status $((Get-Service -Name winrm).Name) - $((Get-Service -Name winrm).Status)" | Send-pSyslog -Server 192.168.3.99
### 02.06.2023: Debug server (check port, log path, unknown message), client (changed message for rsyslog) and changed show parameters

#region Server
function Start-pSyslog {
param(
[int]$Port = 514,
[string]$LogPath = "$home\Documents\pSyslog"
)

if (!(Test-Path $LogPath)) {
New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

$pSyslogJob = Get-job -Name pSyslog -ErrorAction Ignore
if ($pSyslogJob) {
$pSyslogJob | Remove-Job
}

if (Get-NetUDPEndpoint | ? LocalPort -Like $Port) {
Write-Warning "Port $Port is busy"
} else {
Start-Job -Name pSyslog {
$Port = $using:Port
$LogPath = $using:LogPath

Add-Type -TypeDefinition @"
public enum Syslog_Facility {
    kern,
    user,
    mail,
    system,
    security,
    syslog,
    lpr,
    news,
    uucp,
    clock,
    authpriv,
    ftp,
    ntp,
    logaudit,
    logalert,
    cron
}
"@

Add-Type -TypeDefinition @"
public enum Syslog_Severity {
    Emergency,
    Alert,
    Critical,
    Error,
    Warning,
    Notice,
    Informational,
    Debug
}
"@

function Start-pSyslog {
function Add-Socket {
$Socket = New-Object Net.Sockets.Socket(
[Net.Sockets.AddressFamily]::Internetwork,
[Net.Sockets.SocketType]::Dgram,
[Net.Sockets.ProtocolType]::Udp
)
$ServerIPEndPoint = New-Object Net.IPEndPoint(
[Net.IPAddress]::Any,
$Port
)
$Socket.Bind($ServerIPEndPoint)
Return $Socket
}

$Socket = Add-Socket

$Buffer = New-Object Byte[] 1024
$SenderIPEndPoint = New-Object Net.IPEndPoint([Net.IPAddress]::Any, 0)
$SenderEndPoint = [Net.EndPoint]$SenderIPEndPoint

try {
While ($True) {
$IPAddressToString = $SenderEndPoint.Address.IPAddressToString

$BytesReceived = $Socket.ReceiveFrom($Buffer, [Ref]$SenderEndPoint)
$Message = $Buffer[0..$($BytesReceived - 1)]
$MessageString = [Text.Encoding]::ASCII.GetString($Message)

# Example syslog message: <30>Jun  2 13:33:05 zabbix-01 multipathd[783]: sda: add missing path
if ($MessageString -match "<\d+>") {
$Priority = [Int]($MessageString -Replace "<|>.*")
$MessageString = $MessageString -Replace "<$Priority>"

[int]$FacilityInt = [Math]::truncate([decimal]($Priority / 8))
$Facility = [Enum]::ToObject([Syslog_Facility], $FacilityInt)
[int]$SeverityInt = $Priority - ($FacilityInt * 8 )
$Severity = [Enum]::ToObject([Syslog_Severity], $SeverityInt)

switch($Severity) {
Informational {$Fore = 'Green'}
Warning       {$Fore = 'Yellow'}
Error         {$Fore = 'Red'}
Critical      {$Fore = 'Red'}
Emergency     {$Fore = 'Red'}
Alert         {$Fore = 'Red'}
Notice        {$Fore = 'White'}
Debug         {$Fore = 'White'}
default       {$Fore = 'White'}
}

} else {
$Severity  = 'Unknown'
$Fore      = 'DarkCyan'
}

Write-Host "$(Get-Date -Format "dd-MM-yyyy HH:mm:ss") $IPAddressToString" -NoNewline
Write-Host " $Severity" -ForegroundColor $Fore -NoNewline
Write-Host " $MessageString"

$MessageString = "$(Get-Date -Format "dd-MM-yyyy HH:mm:ss") $IPAddressToString $Severity $MessageString"
$LogFile = "$LogPath\$((Get-Date).ToString("dd-MM-yyy")).log"
$MessageString >> $LogFile
}
}

finally {
$socket.Shutdown([System.Net.Sockets.SocketShutdown]::Both)
$Socket.Close()
}
}

Start-pSyslog
} | Out-Null
}
}

function Get-pSyslog {
param(
[switch]$Status
)
$pSyslogJob = Get-job -Name pSyslog -ErrorAction Ignore
if ($pSyslogJob) {
if ($Status) {
$Collections = New-Object System.Collections.Generic.List[System.Object]
$Collections.Add([PSCustomObject]@{
Status = $pSyslogJob.State
StartTime = $pSyslogJob.PSBeginTime
StopTime = $pSyslogJob.PSEndTime
})
$Collections
} else {
While ($True) {
$pSyslogJob | Receive-Job
}
}
}
}

function Stop-pSyslog {
$pSyslogJob = Get-job -Name pSyslog -ErrorAction Ignore
if ($pSyslogJob) {
$pSyslogJob = Get-job -Name pSyslog
$pSyslogJob | Stop-Job
}
}
#endregion

#region Show
function Show-pSyslog {
param(
[ValidateSet("Informational","Warning","Error","Critical","Unknown")][string]$Type,
[switch]$Count,
[string]$LogPath = "$home\Documents\pSyslog"
)

if (Test-Path $LogPath) {
$MessageString = "$(Get-Date -Format "dd-MM-yyyy HH:mm:ss") $IPAddressToString $Severity $MessageString"
$LogFile = "$LogPath\$((Get-Date).ToString("dd-MM-yyy")).log"

if (Test-Path $LogFile) {
$cat = Get-Content $LogFile
$Collections = New-Object System.Collections.Generic.List[System.Object]

foreach ($c in $cat) {
$Text = $c -replace "\s{1,100}"," "
$Text = ($Text -split "]:\s")
$Mess = $Text[0] -split "\s"
if ($mess[8]) {
$Service = $mess[8]+"]"
} else {
$Service = $Null
}

$Collections.Add([PSCustomObject]@{
TimeServer = $mess[0]+" "+$mess[1]
IPAddress = $mess[2]
HostName = $mess[7]
Type = $mess[3]
TimeClient = $mess[5]+" "+$mess[4]+" "+$mess[6]
Service = $Service
Message = $Text[1]
})
}

if ($Type -Like "Informational") {
$Collections = $Collections | ? Type -match "Informational"
}
elseif ($Type -Like "Warning") {
$Collections = $Collections | ? Type -match "Warning"
}
elseif ($Type -Like "Error") {
$Collections = $Collections | ? Type -match "Error"
}
elseif ($Type -Like "Critical") {
$Collections = $Collections | ? Type -match "Critical"
}
elseif ($Type -Like "Unknown") {
$Collections = $Collections | ? Type -match "Unknown"
}
if ($count){
$Collections.Count
} else {
$Collections
}

} else {
Write-Warning "No log file: $LogFile"
}
} else {
Write-Warning "No log directory: $LogPath"
}
}
#endregion

#region Client
function Send-pSyslog {
param(
[Parameter(ValueFromPipeline)][string]$Message,
[string]$Server    = "127.0.0.1",
[int32]$PortServer = 514,
[int32]$PortClient = 55514,
[ValidateSet("Informational")][string]$Type # Add "Warning","Error","Critical"
)
begin {
$UdpObject = New-Object system.Net.Sockets.Udpclient($PortClient)
$UdpObject.Connect($Server, $PortServer)
}

process {
if (!$Type) {
$Type = "Informational"
}
if ($Type = "Informational") {
[int]$NType = 30
}

$Mon = Get-Date -UFormat "%m"
switch($Mon) {
"01" {$Month = 'Jan'}
"02" {$Month = 'Feb'}
"03" {$Month = 'Mar'}
"04" {$Month = 'Apr'}
"05" {$Month = 'May'}
"06" {$Month = 'Jun'}
"07" {$Month = 'Jul'}
"08" {$Month = 'Aug'}
"09" {$Month = 'Sep'}
"10" {$Month = 'Oct'}
"11" {$Month = 'Nov'}
"12" {$Month = 'Dec'}
}
$Day = Get-Date -UFormat "%d"
$Time = Get-Date -UFormat "%H:%M:%S"
$Hostname = [System.Net.Dns]::GetHostName()
$Args = "$Month $Day $Time $Hostname"
$Service = "multipathd[784]:"
$out = "<$NType>$Args $Service $Message"

$ASCIIEncoding = New-Object System.Text.ASCIIEncoding
$Bytes = $ASCIIEncoding.GetBytes($out)
[void]$UdpObject.Send($Bytes, $Bytes.length)
}

end {
$UdpObject.Close()
}
}
#endregion

### Add:
### Checking all message types
### Align output with spaces
### Base64 encryption