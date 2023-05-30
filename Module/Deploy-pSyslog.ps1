$path = ($env:PSModulePath.Split(";")[0])+"\pSyslog\0.2\"
$psd = "$path\pSyslog.psd1"
$psm = "$path\pSyslog-0.2.psm1"
if (!(Test-Path $path)) {
New-Item $psm -ItemType "File" -Force | Out-Null
New-Item $psd -ItemType "File" -Force | Out-Null
}
(New-Object Net.WebClient).DownloadString("https://raw.githubusercontent.com/Lifailon/pSyslog/rsa/Module/pSyslog/0.2/pSyslog.psd1") | Out-File $psd -Encoding default -Force
(New-Object Net.WebClient).DownloadString("https://raw.githubusercontent.com/Lifailon/pSyslog/rsa/Module/pSyslog/0.2/pSyslog-0.2.psm1") | Out-File $psm -Encoding default -Force