function Compare-SPUSolutionFile 
{
    <#

    .SYNOPSIS
    Compare two SPSolution files

    .DESCRIPTION
    Extract the two solution files to a temporary folder to compare the files
    in both directories.

    .PARAMETER ReferenceSolutionPath
    Path to the solution file to be establish as a reference point. Usually the solution
    in the Solution Store.

    .PARAMETER DifferenceSolutionPath
    Path to the solution file to compare against the reference point.

    .EXAMPLE
    Returns the differences between both solution files.
    PS C:\> (Get-SPSolution "TestA.wsp").SolutionFile.SaveAs("C:\TestA.wsp")
    PS C:\> Compare-SPUSolutionFile c:\TestA.wsp c:\new\TestA.wsp

    .LINK
    http://technet.microsoft.com/en-us/library/hh849941(v=wps.620).aspx

    #>
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [ValidatePattern('^.*\.(wsp|WSP)$')]
        [string]$ReferenceSolutionPath,

        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [ValidatePattern('^.*\.(wsp|WSP)$')]
        [string]$DifferenceSolutionPath
    )
    
    begin
    {
        # We use c:\TEMP instead of $env:Temp because 
        # most of the time file paths are more than 255 chars
        $tpath_reff = "C:\TEMP\$([Guid]::NewGuid())"
        $tpath_diff = "C:\TEMP\$([Guid]::NewGuid())"

        New-Item -Path $tpath_reff -ItemType Directory | Out-Null
        New-Item -Path $tpath_diff -ItemType Directory | Out-Null

        Expand $ReferenceSolutionPath  /f:* $tpath_reff | Out-Null
        Expand $DifferenceSolutionPath /f:* $tpath_diff | Out-Null
    }

    process
    {
        Compare-Directory -ReferenceDirectory $tpath_reff -DifferenceDirectory $tpath_diff -Recurse
    }

    end 
    {
        Remove-Item $tpath_reff -Recurse -Force
        Remove-Item $tpath_diff -Recurse -Force
    }

}