### Version 0.5
### Source module: https://github.com/Lifailon/pSyslog
### Documentation used (udp socket): https://metanit.com/sharp/net/3.1.php
### Documentation used (syslog message): https://devconnected.com/syslog-the-complete-system-administrator-guide/
### Source code refactoring syslog server: https://spiderip.com/blog/2018/07/syslog
### Source udp client: https://cloudbrothers.info/en/test-udp-connection-powershell/
###
### Syslog message format:
### <PRI>:  Facility Number (all 24) * 8 + Severity Number (all 8)
### HEADER: TIMESTAMP ([string]mmm + [string][int]dd + hh:mm:ss) and HOSTNAME/IP
### MSG:    TAG and CONTENT
###
### Example:
### Start-pSyslog -Port 514
### Get-pSyslog
### Get-pSyslog -Status
### Stop-pSyslog
### Show-pSyslog | Format-Table
### Show-pSyslog -LogFile 05-06 | Out-GridView 
### Show-pSyslog -Type Warning | Format-Table
### Show-pSyslog -Type Informational -Count
### Send-pSyslog -Content "Test" -Server 192.168.3.102
### (Get-Service -Name WinRM).Status | Send-pSyslog -Server 192.168.3.102 -Tag Service[WinRM]
### Changelog:
### 02.06.2023: Debug server (check port, log path, unknown message), client (changed message for rsyslog) and changed show parameters
### 05.06.2023: Сorrected facilitys, changed buffer size for message on reboot, aligning the output with spaces on the console, сhanged day in TIMESTAMP and added parameters Teg and Types for client, fix parsing for show log file and view old journal by wildcard file name

#region Server
function Start-pSyslog {
param(
[int]$Port = 514,
[string]$LogPath = "$home\Documents\pSyslog"
)

if (!(Test-Path $LogPath)) {
New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

if (Get-NetUDPEndpoint | ? LocalPort -Like $Port) {
Write-Warning "Port $Port is busy"
} else {
$pSyslogJob = Get-job -Name pSyslog -ErrorAction Ignore
if ($pSyslogJob) {
$pSyslogJob | Remove-Job
}

Start-Job -Name pSyslog {
$Port = $using:Port
$LogPath = $using:LogPath

Add-Type -TypeDefinition @"
public enum Syslog_Facility {
    kern,     // 0  kernel (core) messages
    user,     // 1  user level messages
    mail,     // 2  mail system
    daemon,   // 3  system daemons
    auth,     // 4  security/authorization messages (login/su)
    syslog,   // 5  syslog daemon
    lpr,      // 6  line printer subsystem (creating jobs and send to spool for print by using lpd)
    news,     // 7  network news subsystem (USENET)
    uucp,     // 8  Unix-to-Unix Copy subsystem
    cron,     // 9  scheduling daemon
    authpriv, // 10 security/authorization private messages
    ftp,      // 11 FTP daemon
    ntp,      // 12 NTP daemon
    security, // 13 security log audit
    console,  // 14 console log alert
    clock,    // 15 clock subsystem
    local0,   // 16 local use
    local1,   // 17
    local2,   // 18
    local3,   // 19
    local4,   // 20
    local5,   // 21
    local6,   // 22
    local7    // 23
}
"@

Add-Type -TypeDefinition @"
public enum Syslog_Severity {
    Emergency,     // 0 emerg
    Alert,         // 1 alert
    Critical,      // 2 crit
    Error,         // 3 err
    Warning,       // 4 warning
    Notice,        // 5 notice
    Informational, // 6 info
    Debug          // 7 debug
}
"@

function Start-pSyslog {
function Add-Socket {
$Socket = New-Object Net.Sockets.Socket(       # Parameters:
[Net.Sockets.AddressFamily]::Internetwork,     # IPv4 protocol address
[Net.Sockets.SocketType]::Dgram,               # Socket type (socket will receive and send datagrams using the UDP protocol)
[Net.Sockets.ProtocolType]::Udp                # UDP protocol
)
$ServerIPEndPoint = New-Object Net.IPEndPoint( # Server endpoint for receive
[Net.IPAddress]::Any,                          # 0.0.0.0
$Port
)
$Socket.Bind($ServerIPEndPoint)                # Links socket object to local endpoint
Return $Socket
}

$Socket = Add-Socket

$Buffer = New-Object Byte[] 2048                                     # Buffer for get data
$SenderEndPoint = New-Object Net.IPEndPoint([Net.IPAddress]::Any, 0) # Client endpoint for send (IP address and port)

try {
While ($True) {
$IPAddressToString = $SenderEndPoint.Address.IPAddressToString       # Get IP adress client
$BytesReceived = $Socket.ReceiveFrom($Buffer, [Ref]$SenderEndPoint)  # Get data in bytes from Sender and put Buffer
$Message = $Buffer[0..$($BytesReceived - 1)]                         # Split buffer by length
$MessageString = [Text.Encoding]::ASCII.GetString($Message)          # Convert bytes to text

### Debug
### Write-Host "Byte count: $BytesReceived"
### Write-Host "Message in byte: $Message"

if ($MessageString -match "<\d+>") {
$Priority = [Int]($MessageString -Replace "<|>.*")
$MessageString = $MessageString -Replace "<$Priority>"

[int]$FacilityInt = [Math]::truncate([decimal]($Priority / 8)) # Calculate the integer part of a specified decimal number
$Facility = [Enum]::ToObject([Syslog_Facility], $FacilityInt)
[int]$SeverityInt = $Priority - ($FacilityInt * 8 )            # Calculate the remainder
$Severity = [Enum]::ToObject([Syslog_Severity], $SeverityInt)

### Debug
### Write-Host "Priority ($Priority) = (Facility: $FacilityInt[$Facility] * 8) + Severity: $SeverityInt[$Severity]"

$MessageString = $MessageString -replace "\s{1,100}"," "
$Output = "$(Get-Date -Format "dd-MM-yyyy HH:mm:ss") $IPAddressToString $Severity $MessageString"
$LogFile = "$LogPath\$((Get-Date).ToString("dd-MM-yyy")).log"
$Output >> $LogFile

### Console
switch($Severity) {
Debug         {$Fore = "Gray"}
Informational {$Fore = "Green"}
Notice        {$Fore = "Cyan"}
Warning       {$Fore = "Yellow"}
Error         {$Fore = "Red"}
Critical      {$Fore = "Red"}
Alert         {$Fore = "Blue"}
Emergency     {$Fore = "Magenta"}
}

} else {
$Severity  = "Unknown"
$Fore      = "DarkCyan"
}

$Data = ($MessageString -split " ")
$TIMESTAMP = $Data[0..2] -join " "
$HOSTNAME = $Data[3]
$TAG = $Data[4]
$CONTENT = $Data[5..100] -join " "

while ($Severity.Length -ne 14) {
[string]$Severity += " "
}
while ($HOSTNAME.Length -ne 16) {
[string]$HOSTNAME += " "
}
while ($Facility.Length -ne 8) {
[string]$Facility += " "
}
if ($TAG.Length -lt 25) {
while ($TAG.Length -ne 25) {
[string]$TAG += " "
}
}

Write-Host "$TIMESTAMP $HOSTNAME" -NoNewline
Write-Host " $Severity" -ForegroundColor $Fore -NoNewline
Write-Host "$Facility $TAG $CONTENT"
}
}

finally {
$socket.Shutdown([System.Net.Sockets.SocketShutdown]::Both) # Block sending and receiving data before closing the socket
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
[ValidateSet("Informational","Warning","Error","Critical","Alert","Notice","Debug","Emergency","Unknown")][string]$Type,
[switch]$Count,
[string]$LogPath = "$home\Documents\pSyslog",
[string]$LogFile
)

if (Test-Path $LogPath) {
if ($LogFile) {
$FileName = ((ls $LogPath).Name -Match $LogFile)[0]
$LogFile = "$LogPath\$FileName"
} else {
$LogFile = "$LogPath\$((Get-Date).ToString("dd-MM-yyy")).log"
}

if (Test-Path $LogFile) {
$cat = Get-Content $LogFile
$Collections = New-Object System.Collections.Generic.List[System.Object]

foreach ($c in $cat) {
$Data = $c -replace "\s{1,100}"," "
$Data = $Data -split ": "
$SrvData = $Data[0]
$Message = $Data[1..100] -join ": "

$SplitData = $SrvData -split "\s"
if ($SplitData[8]) {
$Service = $SplitData[8]
} else {
$Service = $Null
}

$Collections.Add([PSCustomObject]@{
TimeServer = $SplitData[0]+" "+$SplitData[1]
IPAddress = $SplitData[2]
HostName = $SplitData[7]
Type = $SplitData[3]
TimeClient = $SplitData[5]+" "+$SplitData[4]+" "+$SplitData[6]
Tag = $Service
Message = $Message
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
elseif ($Type -Like "Alert") {
$Collections = $Collections | ? Type -match "Alert"
}
elseif ($Type -Like "Notice") {
$Collections = $Collections | ? Type -match "Notice"
}
elseif ($Type -Like "Debug") {
$Collections = $Collections | ? Type -match "Debug"
}
elseif ($Type -Like "Emergency") {
$Collections = $Collections | ? Type -match "Emergency"
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
[Parameter(ValueFromPipeline)][string]$Content,
[string]$Tag = "Windows[PowerShell]:",
[ValidateSet("Informational","Warning","Error","Critical")][string]$Type,
[string]$Server    = "127.0.0.1",
[int32]$PortServer = 514,
[int32]$PortClient = 55514
)
begin {
$UdpObject = New-Object system.Net.Sockets.Udpclient($PortClient)
$UdpObject.Connect($Server, $PortServer)
}

process {
if (!$Type) {
$Type = "Informational"
}
if ($Type -eq "Informational") {
[int]$NType = 14
}
if ($Type -eq "Warning") {
[int]$NType = 12
}
if ($Type -eq "Error") {
[int]$NType = 11
}
if ($Type -eq "Critical") {
[int]$NType = 10
}

$MMM = Get-Date -UFormat "%m"
switch($MMM) {
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
[string]$Day = Get-Date -Format "%d"
if ([int]$Day -lt 10) {
$Day = $Day -replace "^"," "
}
$TIMESTAMP      = Get-Date -Format "HH:mm:ss"
$HOSTNAME       = [System.Net.Dns]::GetHostName()
[string]$HEADER = "$Month $Day $TIMESTAMP $HOSTNAME"
[string]$MSG    = "<$NType>$HEADER $Tag $Content"

$ASCIIEncoding = New-Object System.Text.ASCIIEncoding
$Bytes = $ASCIIEncoding.GetBytes($MSG)
[void]$UdpObject.Send($Bytes, $Bytes.length)
}

end {
$UdpObject.Close()
}
}
#endregion

### Add:
### Base64 encryption (checking wireshark)
### Rotation logfile
### Template Zabbix/Grafana