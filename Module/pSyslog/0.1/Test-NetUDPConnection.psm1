### Source: https://cloudbrothers.info/en/test-udp-connection-powershell/
### Example:
### Test-NetUDPConnection -ComputerName 127.0.0.1 -PortServer 514

function Test-NetUDPConnection {
param(
[string]$ComputerName = "127.0.0.1",
[int32]$PortServer    = 514,
[int32]$PortClient    = 55514
)
begin {
$UdpObject = New-Object system.Net.Sockets.Udpclient($PortClient)
$UdpObject.Connect($ComputerName, $PortServer)
}
process {
$ASCIIEncoding = New-Object System.Text.ASCIIEncoding
$Message = "<30>May 31 00:00:00 HostName multipathd[784]: Test message"
$Bytes = $ASCIIEncoding.GetBytes($Message)
[void]$UdpObject.Send($Bytes, $Bytes.length)
}
end {
$UdpObject.Close()
}
}