$Tag = (Invoke-RestMethod "https://api.github.com/repos/Lifailon/pSyslog/releases/latest").tag_name
$Ver = "$($Tag -replace "pSyslog-").1"
$path = ($env:PSModulePath.Split(";")[0])+"\pSyslog\"
$psd = "$path\$Ver\pSyslog.psd1"
$psm = "$path\$Ver\pSyslog.psm1"
if (Test-Path $path) {
    Remove-Item "$path\" -Recurse
}
New-Item $psm -ItemType "File" -Force | Out-Null
New-Item $psd -ItemType "File" -Force | Out-Null
(New-Object Net.WebClient).DownloadString("https://raw.githubusercontent.com/Lifailon/pSyslog/rsa/Module/pSyslog/$Ver/pSyslog.psd1") | Out-File $psd -Encoding default -Force
(New-Object Net.WebClient).DownloadString("https://raw.githubusercontent.com/Lifailon/pSyslog/rsa/Module/pSyslog/$Ver/pSyslog.psm1") | Out-File $psm -Encoding default -Force