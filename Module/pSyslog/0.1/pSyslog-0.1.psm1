### Version 0.1
### Compared to the source code: changed output and added closing socket
### Source code refactoring syslog server: https://spiderip.com/blog/2018/07/syslog
### Documentation used: https://metanit.com/sharp/net/3.1.php
### Example:
### Import-Module Start-pSyslog-0.1.psm1
### Start-pSyslog -Port 514

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
param(
[int]$Port = 514,
[string]$LogPath = "$home\documents"
)

function Add-Socket {
$Socket = New-Object Net.Sockets.Socket(
[Net.Sockets.AddressFamily]::Internetwork, # семейство адресов (адрес протокола IPv4)
[Net.Sockets.SocketType]::Dgram, # тип сокета (сокет будет получать и отправлять дейтаграммы по протоколу Udp)
[Net.Sockets.ProtocolType]::Udp # протокол
)
$ServerIPEndPoint = New-Object Net.IPEndPoint( # создать конечную точку сервера для приема (Receive)
[Net.IPAddress]::Any,
$Port
)
$Socket.Bind($ServerIPEndPoint) # связать объект сокета с локальной конечной точкой
Return $Socket
}

$Socket = Add-Socket

$Buffer = New-Object Byte[] 1024 # максимальный размер сообщения
$SenderIPEndPoint = New-Object Net.IPEndPoint([Net.IPAddress]::Any, 0) # конечная точка клиента для отправки (Send)
$SenderEndPoint = [Net.EndPoint]$SenderIPEndPoint # IP адрес и порт клиента (отправителя)
Write-Host "Server started" -ForegroundColor Green

try {
While ($True) {
$IPAddressToString = $SenderEndPoint.Address.IPAddressToString # забрать ip-адрес клиента

$BytesReceived = $Socket.ReceiveFrom($Buffer, [Ref]$SenderEndPoint) # метод полученя данных (байты)
$Message = $Buffer[0..$($BytesReceived - 1)] # сообщение длинной кол-ва полученных байт
$MessageString = [Text.Encoding]::ASCII.GetString($Message) # преобразовать байты в текст
$Priority = [Int]($MessageString -Replace "<|>.*") # забрать цифру приоритета в <..> (28)
$MessageString = $MessageString -Replace "<$Priority>" # удалить приоритет

[int]$FacilityInt = [Math]::truncate([decimal]($Priority / 8)) # получить номер приоритета (3)
$Facility = [Enum]::ToObject([Syslog_Facility], $FacilityInt) # получить значение Facility (system)
[int]$SeverityInt = $Priority - ($FacilityInt * 8 ) # получить номер Severity (4)
$Severity = [Enum]::ToObject([Syslog_Severity], $SeverityInt) # получить значение Severity (Warning)

switch($Severity) {
Informational {$Fore = 'Black'; $Back = 'Green'}
Warning       {$Fore = 'Black'; $Back = 'Yellow'}
Error         {$Fore = 'White'; $Back = 'Red'}
Critical      {$Fore = 'White'; $Back = 'Red'}
Emergency     {$Fore = 'White'; $Back = 'Red'}
Alert         {$Fore = 'White'; $Back = 'Red'}
Notice        {$Fore = 'Black'; $Back = 'white'}
Debug         {$Fore = 'Black'; $Back = 'white'}
default       {$Fore = 'Black'; $Back = 'white'}
}

#Write-Host $MessageString -ForegroundColor $Fore -BackgroundColor $Back
Write-Host "$(Get-Date -Format "dd-MM-yyyy HH:mm:ss") $IPAddressToString" -NoNewline
Write-Host " $Severity" -ForegroundColor $Back -NoNewline
Write-Host " $MessageString"

$MessageString = "$(Get-Date -Format "dd-MM-yyyy HH:mm:ss") $IPAddressToString $Severity $MessageString"
$LogFile = "$LogPath\$((Get-Date).ToString("dd-MM-yyy")).log"
$MessageString >> $LogFile
}
}

finally {
Write-Host "Server stopped" -ForegroundColor Green
$socket.Shutdown([System.Net.Sockets.SocketShutdown]::Both) # блокируются отправка и получение данных перед закрытием сокета
$Socket.Close()
}
}