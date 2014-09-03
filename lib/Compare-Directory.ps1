# Compare-Directory.ps1
# Compare files in one or more directories and return file difference results
# Victor Vogelpoel <victor.vogelpoel@macaw.nl>
# Sept 2013
#
# Disclaimer
# This script is provided AS IS without warranty of any kind. I disclaim all implied warranties including, without limitation,
# any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or
# performance of the sample scripts and documentation remains with you. In no event shall I be liable for any damages whatsoever
# (including, without limitation, damages for loss of business profits, business interruption, loss of business information,
# or other pecuniary loss) arising out of the use of or inability to use the script or documentation.
 
 
# Compare-Directory -ReferenceDirectory "C:\Compare-Directory\FrontEnd1-Site"  -DifferenceDirectory "C:\Compare-Directory\FrontEnd2-Site" 
 
 
function Compare-Directory
{
        <#
        .SYNOPSIS
        Compares a reference directory with one or more difference directories.     
 
        .DESCRIPTION
        Compare-Directory compares a reference directory with one ore more difference
        directories. Files and directories are compared both on filename and contents
        using a MD5hash.
        
        Internally, Compare-Object is used to compare the directories. The behavior
        and results of Compare-Directory is similar to Compare-Object.
 
        .PARAMETER  ReferenceDirectory
        The reference directory to compare one or more difference directories to.
 
        .PARAMETER  DifferenceDirectory
        One or more directories to compare to the reference directory.
 
        .PARAMETER Recurse
        Include subdirectories in the comparison.
            
        .PARAMETER ExcludeFile
        File names to exclude from the comparison.
 
        .PARAMETER ExcludeDirectory
        Directory names to exclude from the comparison. Directory names are 
        relative to the Reference of Difference Directory path
 
        .PARAMETER ExcludeDifferent
        Displays only the characteristics of compared files that are equal.
            
        .PARAMETER IncludeEqual
        Displays characteristics of files that are equal. By default, only 
        characteristics that differ between the reference and difference files 
        are displayed.
 
        .PARAMETER PassThru
        Passes the objects that differed to the pipeline. By default, this 
        cmdlet does not generate any output.
 
        .EXAMPLE
        Compare-Directory -reference "D:\TEMP\CompareTest\path1" -difference "D:\TEMP\CompareTest\path2" -ExcludeFile "web.config" -recurse
            
        Compares directories "D:\TEMP\CompareTest\path1" and "D:\TEMP\CompareTest\path2" recursively, excluding "web.config"
        Only differences are shown. Results:
        
        RelativeBaseName  MD5Hash                          SideIndicator Item                                                                     
        ----------------  -------                          ------------- ----                                                                     
        bin\site.dll      87A1E6006C2655252042F16CBD7FB41B =>            D:\TEMP\CompareTest\path2\bin\site.dll
        index.html        02BB8A33E1094E547CA41B9E171A267B =>            D:\TEMP\CompareTest\path2\index.html                                     
        index.html        20EE266D1B23BCA649FEC8385E5DA09D <=            D:\TEMP\CompareTest\path1\index.html                                     
        web_2.config      5E6B13B107ED7A921AEBF17F4F8FE7AF <=            D:\TEMP\CompareTest\path1\web_2.config                                   
        bin\site.dll      87A1E6006C2655252042F16CBD7FB41B =>            D:\TEMP\CompareTest\path2\bin\site.dll
        index.html        02BB8A33E1094E547CA41B9E171A267B =>            D:\TEMP\CompareTest\path2\index.html                                     
        index.html        20EE266D1B23BCA649FEC8385E5DA09D <=            D:\TEMP\CompareTest\path1\index.html                                     
        web_2.config      5E6B13B107ED7A921AEBF17F4F8FE7AF <=            D:\TEMP\CompareTest\path1\web_2.config                                   
 
        .EXAMPLE
        Compare-Directory -reference "D:\TEMP\CompareTest\path1" -difference "D:\TEMP\CompareTest\path2" -ExcludeFile "web.config" -recurse -IncludeEqual
        
        Compares directories "D:\TEMP\CompareTest\path1" and "D:\TEMP\CompareTest\path2" recursively, excluding "web.config".
        Results include the items that are equal:
        
        RelativeBaseName    MD5Hash                          SideIndicator Item                                                 
        ----------------    -------                          ------------- ----                                                 
        bin                                                  ==            D:\TEMP\CompareTest\path1\bin                        
        bin\site2.dll       98B68D681A8D40FA943D90588E94D1A9 ==            D:\TEMP\CompareTest\path1\bin\site2.dll
        bin\site3.dll       9408C4B29F82260CBBA528342CBAA80F ==            D:\TEMP\CompareTest\path1\bin\site3.dll
        bin\site4.dll       0616E1FBE12D468F611F07768D70C2EE ==            D:\TEMP\CompareTest\path1\bin\site4.dll
        ...
        bin\site8.dll       87A1E6006C2655252042F16CBD7FB41B =>            D:\TEMP\CompareTest\path2\bin\site8.dll
        index.html          02BB8A33E1094E547CA41B9E171A267B =>            D:\TEMP\CompareTest\path2\index.html                 
        index.html          20EE266D1B23BCA649FEC8385E5DA09D <=            D:\TEMP\CompareTest\path1\index.html                 
        web_2.config        5E6B13B107ED7A921AEBF17F4F8FE7AF <=            D:\TEMP\CompareTest\path1\web_2.config               
 
        .EXAMPLE
        Compare-Directory -reference "D:\TEMP\CompareTest\path1" -difference "D:\TEMP\CompareTest\path2" -ExcludeFile "web.config" -recurse -ExcludeDifference
        
        Compares directories "D:\TEMP\CompareTest\path1" and "D:\TEMP\CompareTest\path2" recursively, excluding "web.config".
        Results only include the files that are equal; different files are excluded from the results.
            
        .EXAMPLE
        Compare-Directory -reference "D:\TEMP\CompareTest\path1" -difference "D:\TEMP\CompareTest\path2" -ExcludeFile "web.config" -recurse -Passthru
        
        Compares directories "D:\TEMP\CompareTest\path1" and "D:\TEMP\CompareTest\path2" recursively, excluding "web.config" and returns NO comparison
        results, but the different files themselves!
        
        FullName                                                                                                                                                                  
        --------                                                                                                                                                                  
        D:\TEMP\CompareTest\path2\bin\site3.dll
        D:\TEMP\CompareTest\path2\index.html
        D:\TEMP\CompareTest\path1\index.html
        D:\TEMP\CompareTest\path1\web_2.config
 
        .LINK
        Compare-Object
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, position=0, ValueFromPipelineByPropertyName=$true, HelpMessage="The reference directory to compare one or more difference directories to.")]
        [System.IO.DirectoryInfo]$ReferenceDirectory,
 
        [Parameter(Mandatory=$true, position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, HelpMessage="One or more directories to compare to the reference directory.")]
        [System.IO.DirectoryInfo[]]$DifferenceDirectory,
 
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, HelpMessage="Recurse the directories")]
        [switch]$Recurse,
 
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, HelpMessage="Files to exclude from the comparison")]
        [String[]]$ExcludeFile,
 
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, HelpMessage="Directories to exclude from the comparison")]
        [String[]]$ExcludeDirectory,
 
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, HelpMessage="Displays only the characteristics of compared objects that are equal.")]
        [switch]$ExcludeDifferent,
        
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, HelpMessage="Displays characteristics of files that are equal. By default, only characteristics that differ between the reference and difference files are displayed.")]
        [switch]$IncludeEqual,
        
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, HelpMessage="Passes the objects that differed to the pipeline.")]
        [switch]$PassThru
    )
 
 
    begin
    {
        function Get-MD5
        { 
            [CmdletBinding(SupportsShouldProcess=$false)]
            param
            (
                [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, HelpMessage="file(s) to create hash for")]
                [Alias("File", "Path", "PSPath", "String")]
                [ValidateNotNull()]
                $InputObject
            )
 
            begin
            {
                $cryptoServiceProvider  = [System.Security.Cryptography.MD5CryptoServiceProvider]
                $hashAlgorithm          = new-object $cryptoServiceProvider 
            }
            
            process
            {
                $hashByteArray = ""
                
                $item = Get-Item $InputObject -ErrorAction SilentlyContinue
                if ($item -is [System.IO.DirectoryInfo])    { throw "Cannot create hash for directory" }
                if ($item)                                  { $InputObject = $item }
                
                if ($InputObject -is [System.IO.FileInfo])
                {
                    $stream         = $null; 
                    $hashByteArray  = $null
 
                    try
                    {
                        $stream                 = $InputObject.OpenRead(); 
                        $hashByteArray          = $hashAlgorithm.ComputeHash($stream); 
                    }
                    finally
                    {
                        if ($stream -ne $null)
                        {
                            $stream.Close(); 
                        }
                    }
                }
                else
                {
                    $utf8           = new-object -TypeName "System.Text.UTF8Encoding"
                    $hashByteArray  = $hashAlgorithm.ComputeHash($utf8.GetBytes($InputObject.ToString())); 
                }
 
                Write-Output ([BitConverter]::ToString($hashByteArray)).Replace("-","")
            }
        } 
 
        function Get-Files
        {
            [CmdletBinding(SupportsShouldProcess=$false)]
            param
            (
                [string]$DirectoryPath,
                [String[]]$ExcludeFile,
                [String[]]$ExcludeDirectory,
                [switch]$Recurse
            )
        
            $relativeBasenameIndex = $DirectoryPath.ToString().Length
 
            # Get the files from the first deploypath
            # and ADD the MD5 hash for the file as a property
            # and ADD a filepath relative to the deploypath as a property
            Get-ChildItem -Path $DirectoryPath -Exclude $ExcludeFile -Recurse:$Recurse | foreach { 
                $hash = ""
                if (!$_.PSIsContainer) { $hash = Get-MD5 $_ }
 
                # Added two new properties to the DirectoryInfo/FileInfo objects
                $item = $_ |
                    Add-Member -Name "MD5Hash" -MemberType NoteProperty -Value $hash -PassThru |
                    Add-Member -Name "RelativeBaseName" -MemberType NoteProperty -Value ($_.FullName.Substring($relativeBasenameIndex)) -PassThru
                
                # Test for directories and files that need to be excluded because of ExcludeDirectory
                if ($item.PSIsContainer) { $item.RelativeBaseName += "\" }
                if ($ExcludeDirectory | where { $item.RelativeBaseName -like "\$_\*" })
                {   
                    Write-Verbose "Ignore item `"$($item.Fullname)`""
                }
                else
                {
                    Write-Verbose "Adding `"$($item.Fullname)`" to result set"
                    Write-Output $item 
                }
            }
        }
 
        $referenceDirectoryFiles = Get-Files -DirectoryPath $referenceDirectory -ExcludeFile $ExcludeFile -ExcludeDirectory $ExcludeDirectory -Recurse:$Recurse
    }
 
    process
    {
        if ($DifferenceDirectory -and $referenceDirectoryFiles)
        {
            foreach($nextPath in $DifferenceDirectory)
            {
                $nextDifferenceFiles = Get-Files -DirectoryPath $nextpath -ExcludeFile $ExcludeFile -ExcludeDirectory $ExcludeDirectory -Recurse:$Recurse
                            
                ###################################################
                # Compare the contents of the two file/directory arrays and return the results
                $results = @(Compare-Object -ReferenceObject $referenceDirectoryFiles -DifferenceObject $nextDifferenceFiles -ExcludeDifferent:$ExcludeDifferent -IncludeEqual:$IncludeEqual -PassThru:$PassThru -Property RelativeBaseName, MD5Hash)
                
                if (!$PassThru)
                {
                    foreach ($result in $results)
                    {
                        $path       = $ReferenceDirectory
                        $pathFiles  = $referenceDirectoryFiles
                        if ($result.SideIndicator -eq "=>")
                        {
                            $path       = $nextPath
                            $pathFiles  = $nextDifferenceFiles
                        }
                    
                        # Find the original item in the files array
                        $itemPath = (Join-Path $path $result.RelativeBaseName).ToString().TrimEnd('\')
                        $item = $pathFiles | where { $_.fullName -eq $itemPath }
 
                        $result | Add-Member -Name "Item" -MemberType NoteProperty -Value $item
                    }
                }
                
                Write-Output $results
            }
        }
    }
}