function Export-SPUSolution
{
    <#
        .SYNOPSIS
        Export farm solutions from the SharePoint solutions store

        .DESCRIPTION
        Export all specified solutions to a specific path on the 
        filesystem. 

        .EXAMPLE
        Export-SPUSolution -Path .\solutions_23-07-2014
    
        .EXAMPLE
        Get-SPSolution | ?{$_.Name -Like "Victrix.*"} | Export-SPUSolution -Path .\solutions_23-07-2014

        .EXAMPLE
        Export-SPUSolution -Path .\solutions_23-07-2014 -Compress

    #>
    [CmdletBinding()]
    param(

        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [string]$Path,

        [Parameter(
            ValueFromPipeline = $true
        )]
        [Microsoft.SharePoint.PowerShell.SPSolutionPipeBind[]]$Identity = (Get-SPSolution),

        [switch]$GenerateManifest,
        [switch]$PassThru
    )

    begin
    {
        if(!(Test-Path -Path $Path -PathType Container -IsValid))
        {
            throw "The path is invalid"
        }

        if(!(Test-Path -Path $Path))
        {
            Write-Verbose "Creating directory $Path"
            New-Item -Path $Path -ItemType Directory -ErrorAction "Stop" | Out-Null
        } 

        $detinationPath = Resolve-Path $Path

        $solutions = @()
    }

    process 
    { 
        $solutions += $Identity 
    }

    end 
    { 
        foreach($solutionPipe in $solutions)
        {
            $s = $solutionPipe.Read()
            $sDestPath = "$detinationPath\$($s.Name)"
            $s.SolutionFile.SaveAs("$sDestPath")

            Write-Verbose "Exported solution to $sDestPath"
        }

        if($GenerateManifest) 
        {
            Write-Verbose "Generating solution manifest"
            $solutions | New-SPUSolutionManifest -LiteralPath "$detinationPath\manifest.xml"
        }
        
        if($PassThru)
        { 
            Write-Verbose "Passing solution files" 
            Get-ChildItem $detinationPath -Filter "*.wsp" 
        }

    }

}



