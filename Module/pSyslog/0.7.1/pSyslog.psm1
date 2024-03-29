### Version 0.7.1
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
### Server:
### Start-pSyslog -Port 514
### Start-pSyslog -RotationSize 500 
### Get-pSyslog
### Get-pSyslog -Status
### Stop-pSyslog
###
### Showlog:
### Show-pSyslog -Type Informational | Format-Table
### Show-pSyslog -Type Warning | Out-GridView
### Show-pSyslog -Count
### Show-pSyslog -Count -LogFile 10-06
###
### Client:
### Send-pSyslog -Content "Test" -Server 192.168.3.102
### (Get-Service -Name WinRM).Status | Send-pSyslog -Server 192.168.3.102 -Tag Service[WinRM]
###
### Encryption:
### Send-pSyslog $(Get-Date) -Server 192.168.3.99 -PortServer 514 -Base64
### Wireshark filter: udp.dstport == 514 && ip.src == 192.168.3.100 && !icmp
###
### Relay:
### 192.168.3.102: Start-pSyslog -Port 514
### 192.168.3.99:  Start-UDPRelay -inPort 515 -outIP 192.168.3.102 -outPort 514 
### 192.168.3.100: Send-pSyslog -Server 192.168.3.99 -PortServer 515 -Content $(Get-Date)
###
### Changelog:
### 02.06.2023: Debug server (check port, log path, unknown message), client (changed message for rsyslog) and changed show parameters
### 05.06.2023: Сorrected facilitys, changed buffer size for message on reboot, aligning the output with spaces on the console, сhanged day in TIMESTAMP and added parameters Teg and Types for client, fix parsing for show log file and view old journal by wildcard file name
### 08.05.2023: Added server UDP Relay, parameter for send in Base64 encryption and closing ReceiveFrom call for stop server
### 10.05.2023: Added logfile rotation and show all log files in 24 hours
### 20.02.2023: Formatting code and output to utf8 file

#region Server
function Start-pSyslog {
    param(
        [int]$Port = 514,
        [string]$LogPath = "$home\Documents\pSyslog",
        [string]$RotationSize = "2000",
        [switch]$NoRotation,
        [switch]$NoAligning
    )

    if (!(Test-Path $LogPath)) {
        New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
    }

    if (Get-NetUDPEndpoint | Where-Object LocalPort -Like $Port) {
        Write-Warning "Port $Port is busy"
        Return
    }

    $pSyslogJob = Get-Job -Name pSyslog-Server -ErrorAction Ignore

    if ($pSyslogJob) {
        if ((Get-Job -Name pSyslog-Server).State -like "Stopped") {
            $pSyslogJob | Remove-Job	
        }

        elseif ((Get-Job -Name pSyslog-Server).State -like "Running") {
            Write-Warning "Server is running on $PortJob port"
            Return
        }
    }

    $Global:PortJob = $Port

    Start-Job -Name pSyslog-Server {
        $Port = $using:Port
        $LogPath = $using:LogPath
        $RotationSize = $using:RotationSize
        $NoRotation = $using:NoRotation
        $NoAligning = $using:NoAligning

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
                $Socket = New-Object System.Net.Sockets.Socket(       # Parameters:
                    [System.Net.Sockets.AddressFamily]::Internetwork, # IPv4 protocol address
                    [System.Net.Sockets.SocketType]::Dgram,           # Socket type (socket will receive and send datagrams using the UDP protocol)
                    [System.Net.Sockets.ProtocolType]::Udp            # UDP protocol
                )
                $ServerIPEndPoint = New-Object System.Net.IPEndPoint( # Server endpoint for receive
                    [System.Net.IPAddress]::Any,                      # 0.0.0.0
                    $Port
                )
                $Socket.Bind($ServerIPEndPoint)                       # Links socket object to local endpoint
                Return $Socket
            }

            $Socket = Add-Socket
            $Buffer = New-Object Byte[] 2048                          # Buffer for get data
            $SenderEndPoint = New-Object System.Net.IPEndPoint(       # Client endpoint for send
                [System.Net.IPAddress]::Any,
                0
            )

            try {
                While ($True) {                                                         
                    $IPAddressToString = $SenderEndPoint.Address.IPAddressToString          # Get IP adress client

                    ### public int ReceiveFrom(byte[] buffer, ref EndPoint remoteEP) 
                    ### this.ReceiveFrom(buffer, 0, buffer != null ? buffer.Length : 0, SocketFlags.None, ref remoteEP);

                    $BytesReceived = $Socket.ReceiveFrom($Buffer, [Ref]$SenderEndPoint) # Receive data in bytes from Sender to Buffer
                    $Message = $Buffer[0..$($BytesReceived - 1)]                        # Split buffer by Length
                    $String = [System.Text.Encoding]::ASCII.GetString($Message)         # Convert bytes to text

                    if ($String -match "\=$") {
                        # Condition to check the string for Base64 format
                        $DecodeBase64 = [System.Convert]::FromBase64String($String)             # Decode Base64 to byte
                        $MessageString = [System.Text.Encoding]::ASCII.GetString($DecodeBase64) # Convert bytes to text
                    }
                    else {
                        $MessageString = $String
                    }

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

                        $MessageString = $MessageString -replace "\s{1,100}", " "
                        $Output = "$(Get-Date -Format "dd-MM-yyyy HH:mm:ss") $IPAddressToString $Severity $MessageString"

                        ### Rotation
                        $date = $((Get-Date).ToString("dd-MM-yyy"))
                        $ls = Get-ChildItem "$LogPath\$date*"

                        if ($ls) {
                            $LogFile = ($ls | Sort-Object LastWriteTime)[-1].FullName
                            if (!($NoRotation)) {
                                $size = [Int]((Get-ChildItem $LogFile | Measure-Object -Property Length -Sum).Sum / 1Kb)
                                if ($size -ge $RotationSize) {
                                    [int]$OldNum = $LogFile -replace "$date|.+\-|.log"
                                    [int]$NewNum = $OldNum + 1
                                    $LogFile = $LogFile -replace "$OldNum.log", "$NewNum.log"
                                }
                            }
                        }
                        else {
                            $LogFile = "$LogPath\$date-1.log"
                        }

                        $Output | Out-File -FilePath $LogFile -Encoding utf32 -Append

                        ### Console
                        switch ($Severity) {
                            Debug { $Fore = "Gray" }
                            Informational { $Fore = "Green" }
                            Notice { $Fore = "Cyan" }
                            Warning { $Fore = "Yellow" }
                            Error { $Fore = "Red" }
                            Critical { $Fore = "Red" }
                            Alert { $Fore = "Blue" }
                            Emergency { $Fore = "Magenta" }
                        }

                    }
                    else {
                        $Severity = "Unknown"
                        $Fore = "DarkCyan"
                    }

                    $Data = ($MessageString -split " ")
                    $TIMESTAMP = $Data[0..2] -join " "
                    $HOSTNAME = $Data[3]
                    $TAG = $Data[4]
                    $CONTENT = $Data[5..100] -join " "

                    ### Aligning
                    if (!($NoAligning)) {
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
                    }

                    Write-Host "$TIMESTAMP $HOSTNAME" -NoNewline
                    Write-Host " $Severity " -ForegroundColor $Fore -NoNewline
                    Write-Host "$Facility $TAG $CONTENT"
                }
            }

            finally {
                $Socket.Shutdown([System.Net.Sockets.SocketShutdown]::Both) # Block sending and receiving data before closing the socket
                $Socket.Close()
            }
        }

        Start-pSyslog
    } | Out-Null
}
#endregion

#region Get/Stop
function Get-pSyslog {
    param(
        [switch]$Status
    )
    $pSyslogJob = Get-Job -Name pSyslog-Server -ErrorAction Ignore
    if ($pSyslogJob) {
        if ($Status) {
            $Collections = New-Object System.Collections.Generic.List[System.Object]
            $Collections.Add([PSCustomObject]@{
                    Status    = $pSyslogJob.State
                    StartTime = $pSyslogJob.PSBeginTime
                    StopTime  = $pSyslogJob.PSEndTime
                })
            $Collections
        }
        else {
            While ($True) {
                $pSyslogJob | Receive-Job
            }
        }
    }
}

function Stop-pSyslog {
    Start-Job -Name pSyslog-Stopped {
        Start-Sleep 3
        $PortJob = $using:PortJob
        Import-Module pSyslog
        Send-pSyslog -Content "Stopped pSyslog" -Server 127.0.0.1 -PortServer $PortJob
    } | Out-Null

    $pSyslogJob = Get-Job -Name pSyslog-Server -ErrorAction Ignore
    if ($pSyslogJob) {
        Stop-Job -Name pSyslog-Server
    }

    while ($True) {
        if ((Get-Job -Name pSyslog-Stopped).State -like "Completed") {
            Remove-Job -Name pSyslog-Stopped
            Return
        }
    }
}
#endregion

#region Show
function Show-pSyslog {
    param(
        [ValidateSet("Informational", "Warning", "Error", "Critical", "Alert", "Notice", "Debug", "Emergency", "Unknown")][string]$Type,
        [switch]$Count,
        [string]$LogFile,
        [string]$LogPath = "$home\Documents\pSyslog"
    )

    if (!(Test-Path $LogPath)) {
        Write-Warning "No log directory: $LogPath"
        Return
    }

    if ($LogFile) {
        $FileMatch = (Get-ChildItem $LogPath | Where-Object Name -Match $LogFile)
        if ($FileMatch.Count -ne 0) {
            $LogFiles = ($FileMatch | Sort-Object LastWriteTime).FullName
        }
        else {
            Write-Warning "No log file: $LogFile"
            Return
        }
    }
    else {
        $Date = (Get-Date).ToString("dd-MM-yyy")
        $FileMatch = ((Get-ChildItem $LogPath) | Where-Object Name -Match $Date)
        if ($FileMatch.Count -ne 0) {
            $LogFiles = ($FileMatch | Sort-Object LastWriteTime).FullName
        }
        else {
            Write-Warning "No log file: $Date"
            Return
        }
    }

    foreach ($LogFile in $LogFiles) {
        $cat += Get-Content $LogFile
    }

    $Collections = New-Object System.Collections.Generic.List[System.Object]

    foreach ($c in $cat) {
        $Data = $c -replace "\s{1,100}", " "
        $Data = $Data -split ": "
        $SrvData = $Data[0]
        $Message = $Data[1..100] -join ": "

        $SplitData = $SrvData -split "\s"
        if ($SplitData[8]) {
            $Service = $SplitData[8]
        }
        else {
            $Service = $Null
        }

        $Collections.Add([PSCustomObject]@{
                TimeServer = $SplitData[0] + " " + $SplitData[1]
                IPAddress  = $SplitData[2]
                HostName   = $SplitData[7]
                Type       = $SplitData[3]
                TimeClient = $SplitData[5] + " " + $SplitData[4] + " " + $SplitData[6]
                Tag        = $Service
                Message    = $Message
            })
    }

    if ($Type -Like "Informational") {
        $Collections = $Collections | Where-Object Type -match "Informational"
    }
    elseif ($Type -Like "Warning") {
        $Collections = $Collections | Where-Object Type -match "Warning"
    }
    elseif ($Type -Like "Error") {
        $Collections = $Collections | Where-Object Type -match "Error"
    }
    elseif ($Type -Like "Critical") {
        $Collections = $Collections | Where-Object Type -match "Critical"
    }
    elseif ($Type -Like "Alert") {
        $Collections = $Collections | Where-Object Type -match "Alert"
    }
    elseif ($Type -Like "Notice") {
        $Collections = $Collections | Where-Object Type -match "Notice"
    }
    elseif ($Type -Like "Debug") {
        $Collections = $Collections | Where-Object Type -match "Debug"
    }
    elseif ($Type -Like "Emergency") {
        $Collections = $Collections | Where-Object Type -match "Emergency"
    }
    elseif ($Type -Like "Unknown") {
        $Collections = $Collections | Where-Object Type -match "Unknown"
    }
    if ($count) {
        $Collections.Count
    }
    else {
        $Collections
    }
}
#endregion

#region Client
function Send-pSyslog {
    param(
        [Parameter(ValueFromPipeline)][string]$Content,
        [string]$Tag = "Windows[PowerShell]:",
        [ValidateSet("Informational", "Warning", "Error", "Critical")][string]$Type,
        [string]$Server = "127.0.0.1",
        [int32]$PortServer = 514,
        [int32]$PortClient = 55514,
        [switch]$Base64
    )
    begin {
        $UdpObject = New-Object System.Net.Sockets.Udpclient($PortClient)
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
        switch ($MMM) {
            "01" { $Month = 'Jan' }
            "02" { $Month = 'Feb' }
            "03" { $Month = 'Mar' }
            "04" { $Month = 'Apr' }
            "05" { $Month = 'May' }
            "06" { $Month = 'Jun' }
            "07" { $Month = 'Jul' }
            "08" { $Month = 'Aug' }
            "09" { $Month = 'Sep' }
            "10" { $Month = 'Oct' }
            "11" { $Month = 'Nov' }
            "12" { $Month = 'Dec' }
        }
        [string]$Day = Get-Date -Format "%d"
        if ([int]$Day -lt 10) {
            $Day = $Day -replace "^", " "
        }
        $TIMESTAMP = Get-Date -Format "HH:mm:ss"
        $HOSTNAME = [System.Net.Dns]::GetHostName()
        [string]$HEADER = "$Month $Day $TIMESTAMP $HOSTNAME"
        [string]$MSG = "<$NType>$HEADER $Tag $Content"

        if ($Base64) {
            $TextToByte = [System.Text.Encoding]::ASCII.GetBytes($MSG)
            $ByteToBase64 = [System.Convert]::ToBase64String($TextToByte)
            $Bytes = [System.Text.Encoding]::ASCII.GetBytes($ByteToBase64)
        }
        else {
            $Bytes = [System.Text.Encoding]::ASCII.GetBytes($MSG)
        }

        [void]$UdpObject.Send($Bytes, $Bytes.Length)
    }

    end {
        $UdpObject.Close()
    }
}
#endregion

#region Relay
function Start-UDPRelay {
    param(
        [int]$inPort = 514, # Input/Source/Listener
        [string]$outIP,     # Output/Destination
        [int]$outPort = 514
    )

    if (Get-NetUDPEndpoint | Where-Object LocalPort -Like $inPort) {
        Write-Warning "Port $inPort is busy"
    }
    else {

        function Add-Socket {
            $SocketServer = New-Object System.Net.Sockets.Socket(
                [System.Net.Sockets.AddressFamily]::Internetwork,
                [System.Net.Sockets.SocketType]::Dgram,
                [System.Net.Sockets.ProtocolType]::Udp
            )
            $ServerIPEndPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, $inPort)
            $SocketServer.Bind($ServerIPEndPoint)
            Return $SocketServer
        }

        $SocketServer = Add-Socket
        $Buffer = New-Object Byte[] 8192
        $SenderEndPoint = New-Object System.Net.IPEndPoint([Net.IPAddress]::Any, 0)

        $UdpClient = New-Object System.Net.Sockets.UdpClient
        $UdpClient.Connect($outIP, $outPort)

        try {
            While ($True) {
                $BytesReceived = $SocketServer.ReceiveFrom($Buffer, [Ref]$SenderEndPoint)
                $Message = $Buffer[0..$($BytesReceived - 1)]
                $MessageString = [System.Text.Encoding]::ASCII.GetString($Message)

                ### Debug
                Write-Host "Message in byte: " -NoNewline  -ForegroundColor Green
                Write-Host $Message
                Write-Host "Length bytes: " -NoNewline  -ForegroundColor Green
                Write-Host $BytesReceived
                Write-Host "Message encoding to text: " -NoNewline  -ForegroundColor Green
                Write-Host $MessageString
                Write-Host

                [void]$UdpClient.Send($Message, $Message.Length)
            }
        }
        finally {
            $UdpClient.Close()
            $SocketServer.Shutdown([System.Net.Sockets.SocketShutdown]::Both)
            $SocketServer.Close()
        }
    }
}
#endregion