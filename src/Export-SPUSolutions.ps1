Function Export-SPUSolution
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
            Position = 0,
            ValueFromPipeline = $true
        )]
        [Microsoft.SharePoint.PowerShell.SPSolutionPipeBind[]]$Identity = (Get-SPSolution),

        [string]$Path = $PWD
    )

    begin
    {
        # We create the destination directory
        if(!(Test-Path -Path $Path) -and 
            (Test-Path -Path $Path -PathType Container -IsValid))
        {
            New-Item -Path $Path -ItemType Directory -ErrorAction "Stop"
        }
        else {
            throw "The path is invalid"
        }

        $detinationPath = Resolve-Path $Path
    }

    process
    {   
        foreach($pipe in $Identity)
        {
            $s = $pipe.Read()
            Write-Host "-> $($s.Name)"
            $s.SolutionFile.SaveAs("$detinationPath\$($s.Name)") 
        }
    }

    end 
    { 
        
    }

}