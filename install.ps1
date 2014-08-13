$wclient = New-Object System.Net.WebClient
$shell   = New-Object -Com Shell.Application 

$url     = "https://github.com/maximebedard/SPU/archive/master.zip"
$zipPath = "$($env:temp)\spu-master.zip"
$dest    = "$home\Documents\WindowsPowerShell\Modules"

$wclient.DownloadFile($url,$zipPath)
$zip = $shell.Namespace($zipPath)

$zip.Items() | %{
    $shell.Namespace($dest).copyhere($_)
}

Rename-Item "$dest\spu-master" "SPU"
