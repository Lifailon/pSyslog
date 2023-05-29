### Refacroting code from source: https://spiderip.com/blog/2018/07/syslog

$LogFolder = "$home\documents"
$SysLogPort = 514
$Buffer = New-Object Byte[] 1024
$EnableMessageValidation = $True
$EnableLocalLogging = $True
$EnableConsoleLogging = $True
$EnableHostNameLookup = $false
$EnableHostNamesOnly = $true

$day = Get-Date -Format "dd"
$month = Get-Date -Format "MM"
$year = Get-Date -Format "yyyy"
$today = "$day-$month-$year"

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

function Start-SysLog {
$Socket = Add-Socket
Start-Receive $Socket
}

function Add-Socket {
$Socket = New-Object Net.Sockets.Socket(
[Net.Sockets.AddressFamily]::Internetwork,
[Net.Sockets.SocketType]::Dgram,
[Net.Sockets.ProtocolType]::Udp
)

$ServerIPEndPoint = New-Object Net.IPEndPoint(
[Net.IPAddress]::Any,
$SysLogPort
)

$Socket.Bind($ServerIPEndPoint)
Return $Socket
}

function Start-Receive([Net.Sockets.Socket]$Socket) {
$SenderIPEndPoint = New-Object Net.IPEndPoint([Net.IPAddress]::Any, 0)
$SenderEndPoint = [Net.EndPoint]$SenderIPEndPoint

$ServerRunning = $True
While ($ServerRunning -eq $True) {
$BytesReceived = $Socket.ReceiveFrom($Buffer, [Ref]$SenderEndPoint)
$Message = $Buffer[0..$($BytesReceived - 1)]

$MessageString = [Text.Encoding]::ASCII.GetString($Message)

$Priority = [Int]($MessageString -Replace "<|>.*")  

[int]$FacilityInt = [Math]::truncate([decimal]($Priority / 8))
$Facility = [Enum]::ToObject([Syslog_Facility], $FacilityInt)
[int]$SeverityInt = $Priority - ($FacilityInt * 8 )
$Severity = [Enum]::ToObject([Syslog_Severity], $SeverityInt)

$HostName =  $SenderEndPoint.Address.IPAddressToString

if($Facility -eq "System") {
$MessageString = "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] $HostName <$Severity> - $MessageString"
} else {
$MessageString = "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] $HostName <$Severity> - $MessageString"
}
switch($Severity) {
Emergency     {$Fore = 'White'; $Back = 'Red'}
Alert         {$Fore = 'White'; $Back = 'Red'}
Error         {$Fore = 'Red';   $Back = 'Black'}
Critical      {$Fore = 'Red';   $Back = 'Black'}
Warning       {$Fore = 'Black'; $Back = 'Yellow'}
Notice        {$Fore = 'Black'; $Back = 'white'}
Informational {$Fore = 'Black'; $Back = 'Green'}
Debug         {$Fore = 'Black'; $Back = 'white'}
default       {$Fore = 'White'; $Back = 'Red'}
}

Write-Host $MessageString -ForegroundColor $Fore -BackgroundColor $Back

$Day = (Get-Date).Day
$DateStamp = (Get-Date).ToString("yyyyMMdd")
$LogFile = "$LogFolder$DateStamp.log"
$MessageString >> $LogFile
}
}

Start-SysLog