$path = ($env:PSModulePath.Split(";")[0])+"\pSyslog\0.2\"
$psm = "$path\pSyslog.psd1"
$psd = "$path\pSyslog-0.2.psm1"
if (!(Test-Path $path)) {
New-Item $psm -ItemType "File" -Force | Out-Null
New-Item $psd -ItemType "File" -Force | Out-Null
}
(iwr https://raw.githubusercontent.com/Lifailon/Veeam-REStat/rsa/Veeam-REStat/Veeam-REStat.psm1).Content | Out-File $path -Force