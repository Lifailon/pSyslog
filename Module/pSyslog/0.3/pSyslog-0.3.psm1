### Version 0.3
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
### Show-pSyslog
### Show-pSyslog -Informational # [-Warning] [-Error] [-Critical]
### "Test message" | Send-pSyslog -Server 192.168.3.99

function Start-pSyslog {
param(
[int]$Port = 514,
[string]$LogPath = "$home\documents"
)

$pSyslogJob = Get-job -Name pSyslog -ErrorAction Ignore
if ($pSyslogJob) {
$pSyslogJob | Remove-Job
}
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
Notice        {$Fore = 'white'}
Debug         {$Fore = 'white'}
default       {$Fore = 'white'}
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

function Show-pSyslog {
param(
[switch]$Informational,
[switch]$Warning,
[switch]$Error,
[switch]$Critical,
[string]$LogPath = "$home\documents"
)
$MessageString = "$(Get-Date -Format "dd-MM-yyyy HH:mm:ss") $IPAddressToString $Severity $MessageString"
$LogFile = "$LogPath\$((Get-Date).ToString("dd-MM-yyy")).log"
$cat = Get-Content $LogFile
$Collections = New-Object System.Collections.Generic.List[System.Object]

foreach ($c in $cat) {
$Text = ($c -split "]:\s")
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

if ($Informational) {
($Collections | ? Type -match "Informational").Count
}
elseif ($Warning) {
($Collections | ? Type -match "Warning").Count
}
elseif ($Error) {
($Collections | ? Type -match "Error").Count
}
elseif ($Critical) {
($Collections | ? Type -match "Critical").Count
}
else {
$Collections
}
}

function Send-pSyslog {
param(
[Parameter(ValueFromPipeline)]$Message,
[string]$Server    = "127.0.0.1",
[int32]$PortServer = 514,
[int32]$PortClient = 55514
)
begin {
$UdpObject = New-Object system.Net.Sockets.Udpclient($PortClient)
$UdpObject.Connect($Server, $PortServer)
}
process {
$ASCIIEncoding = New-Object System.Text.ASCIIEncoding

$Mon = Get-Date -UFormat "%m"
switch($Mon) {
"01" {$Month = 'January'}
"02" {$Month = 'February'}
"03" {$Month = 'March'}
"04" {$Month = 'April'}
"05" {$Month = 'May'}
"06" {$Month = 'June'}
"07" {$Month = 'July'}
"08" {$Month = 'August'}
"09" {$Month = 'September'}
"10" {$Month = 'October'}
"11" {$Month = 'November'}
"12" {$Month = 'December'}
}
$Day = Get-Date -UFormat "%d"
$Time = Get-Date -UFormat "%H:%M:%S"
$Hostname = [System.Net.Dns]::GetHostName()
$Service = "multipathd[784]:"
$out = "<30>$Month $Day $Time $Hostname $Service $Message"

$Bytes = $ASCIIEncoding.GetBytes($out)
[void]$UdpObject.Send($Bytes, $Bytes.length)
}
end {
$UdpObject.Close()
}
}