$wclient = New-Object System.Net.WebClient
$shell   = New-Object -Com Shell.Application 

$url     = "https://github.com/maximebedard/SPU/archive/master.zip"
$zipPath = "$($env:temp)\spu-master.zip"
$dest    = "$home\Documents\WindowsPowerShell\Modules"

if(Test-Path "$dest\SPU")
{
    Remove-Item "$dest\SPU" -Confirm -Recurse -Force
    if(Test-Path "$dest\SPU") { return }
}

$wclient.DownloadFile($url,$zipPath)
$zip = $shell.Namespace($zipPath)

$zip.Items() | %{
    $shell.Namespace($dest).copyhere($_)
}

Rename-Item "$dest\spu-master" "SPU"
