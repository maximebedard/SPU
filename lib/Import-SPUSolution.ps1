function Import-SPUSolution
{
    [CmdletBinding()]
    param(
        [string]$Path = "$PWD\manifest.xml",

        [scriptblock[]]$BeforeCallback = @(),
        [scriptblock[]]$AfterCallback = @(),

        [scriptblock[]]$BeforeActionCallback = @(),
        [scriptblock[]]$AfterActionCallback = @(),

        [hashtable]$Parameters = @{
            env="dev"
        },
        [switch]$Cleanup
    )

    # Prepend default callbacks
    $DefaultBeforeCallbacks       = @(${function:Restart-SPUAdministrationService})
    $DefaultAfterCallbacks        = @(${function:Restart-SPUTimerService})
    $DefaultBeforeActionCallbacks = @()
    $DefaultAfterActionCallbacks  = @(${function:Restart-SPUApplicationPools})

    $BeforeCallback       = $DefaultBeforeCallbacks + $BeforeCallback
    $AfterCallback        = $DefaultAfterCallbacks + $AfterCallback
    $BeforeActionCallback = $DefaultBeforeActionCallbacks + $BeforeActionCallback
    $AfterActionCallback  = $DefaultAfterActionCallbacks + $AfterActionCallback


    if(Test-Path -Path $Path -Filter "*.xml" -PathType Leaf)
    {
        Write-Verbose "Reading manifest $Path"

        # EXTRACT THIS
        $content = Get-Content $Path -Encoding UTF8 -ErrorAction Stop

        if ($PSVersionTable.PSVersion.Major -lt 3) { $content = $content -replace '"', '`"' }

        $config = [xml]$ExecutionContext.InvokeCommand.ExpandString($content)

        $BeforeCallback | %{ & $_ }

        foreach($solutionElem in $config.SelectNodes("/Solutions/Solution"))
        {
            $name       = $solutionElem.Name
            $webApps    = ($solutionElem.SelectNodes("./WebApplications/WebApplication/@Url") | Select -ExpandProperty "#text")
            $webAppsStr = $webApps -join ", "

            $state      = Get-SPUSolutionState -Identity $name -WebApplication $webApps -Cleanup:$Cleanup
            
            Write-Verbose "Processing solution $name"
            Write-Host "$name" -Foreground Cyan

            while(@("Installed", "Uninstalled") -notcontains $state)
            {
                Write-Host " => $state" -Foreground DarkCyan
                $BeforeActionCallback | %{ & $_ $name $state}
                
                switch($state)
                {
                    "Add" 
                    {
                        Write-Verbose "Adding $name to the solution store"
                        Add-SPSolution -LiteralPath "$PWD\$name" | Out-Null
                    }

                    "Deploy" 
                    {

                        # refactor
                        if(($webApps -ne $null) -and (@($webApps).Count -gt 0))
                        {
                            Write-Verbose "Deploying $name to the the following web applications : $webAppsStr"
                            $webApps | %{
                                Install-SPSolution -Identity $name -WebApplication $_ -GACDeployment
                                Wait-SPUSolutionJob -Identity $name
                            }
                        }
                        else 
                        {
                            Write-Verbose "Deploying $name globally"     
                            Install-SPSolution -Identity $name -GACDeployment 
                            Wait-SPUSolutionJob -Identity $name
                        }
                    }

                    "Update" 
                    {
                        throw "Not implemented yet"
                    }

                    "Retract"
                    {
                        # refactor
                        if(($webApps -ne $null) -and (@($webApps).Count -gt 0))
                        {
                            Write-Verbose "Retracting $name to the the following web applications : $webAppsStr"
                            $webApps | %{
                                Uninstall-SPSolution -Identity $name -WebApplication $_ -Confirm:$false 
                                Wait-SPUSolutionJob -Identity $name
                            }
                        }
                        else 
                        {
                            Write-Verbose "Retracting $name globally"
                            Uninstall-SPSolution -Identity $name -Confirm:$false    
                            Wait-SPUSolutionJob -Identity $name
                        }
                    }

                    "Remove" 
                    {
                        Write-Verbose "Removing $name from the solution store"
                        Remove-SPSolution -Identity $name -Confirm:$false
                    }
                }
                
                $AfterActionCallback | %{ & $_ $name $state}

                $state = Get-SPUSolutionState -Identity $name -WebApplication $webApps -PreviousState $state -Cleanup:$Cleanup
            }

            Write-Host " => $state!" -Foreground Green
        }

        $AfterCallback | %{ & $_ }

    }
    elseif(Test-Path -Path $Path -PathType Container) 
    {
        Write-Verbose "Searching for manifest in the directory $Path"
        
        Import-SPUSolution -Path "$Path\manifest.xml" -Parameters $Parameters
    }
    else 
    {
        throw "Solution manifest not found. Please create a new manifest.xml file."        
    }

}

function Wait-SPUSolutionJob
{
    param(
        [Microsoft.SharePoint.PowerShell.SPSolutionPipeBind[]]$Identity,
        [int]$DefaultTimeOut = 30,
        [int]$Tick = 2
    )

    process
    {
        $Identity | %{
            $s = $_.Read()
            $waitedTime = 0
            $wait = $true
            do
            {
                if($s.JobExists)
                {
                    Start-Sleep $Tick
                    $waitedTime += $Tick
                }
                else 
                {
                    $wait = $false    
                }
            }
            while($wait -or $waitedTime -ge $DefaultTimeOut)

            if($waitedTime -ge $DefaultTimeOut)
            {
                throw "The solution deployment job has timed out. "
            }

            switch($s.LastOperationResult)
            {
                "NoOperationPerformed" { return }
                "RetractionSucceeded" { return }
                "DeploymentSucceeded" { return }
                default 
                {
                    throw "$s.LastOperationDetails"
                }
            }

        }
    }
}

function Get-SPUSolutionState
{
    param(
        [Microsoft.SharePoint.PowerShell.SPSolutionPipeBind[]]$Identity,
        
        [string[]]$WebApplication,

        [ValidateSet("Add", "Update", "Retract", "Remove", "Deploy", "Installed", $null)]
        [string]$PreviousState = $null,

        [switch]$Cleanup
    )

    process
    {
        $Identity | %{

            if($Cleanup)
            {
                if(Test-SPUSolutionDeployed -Identity $Identity -WebApplication $WebApplication -AnyWebApplication)
                {
                    return "Retract"
                }

                if(Test-SPUSolutionAdded -Identity $Identity)
                {
                    return "Remove"
                }

                return "Uninstalled"
            }
            else 
            {
                if(($PreviousState -eq "Retract") -and (Test-SPUSolutionAdded -Identity $Identity))
                {
                    return "Remove"
                }

                if(-not (Test-SPUSolutionAdded -Identity $Identity))
                {
                    return "Add"
                }
            
                #if(Test-SPUSolutionNeedUpdate -Identity $Identity)
                #{
                #    return "Update"
                #}
                
                #if(Test-SPUSolutionNeedReinstall -Identity $Identity)
                #{
                #    return "Retract"
                #}

                if(-not (Test-SPUSolutionDeployed -Identity $Identity -WebApplication $WebApplication))
                {
                    return "Deploy"
                }
                
                return "Installed"
            }
        
        }
    }
}

function Test-SPUSolutionNeedUpdate 
{
    <#
    TODO
    #>
    param(
        [Microsoft.SharePoint.PowerShell.SPSolutionPipeBind[]]$Identity
    )

    process
    {
        $Identity | %{

            if(-not (Test-SPUSolutionAdded -Identity $_))
            {
                return $false
            }
        
            $s = $_.Read()

            # Download the stored solution into a temporary folder
            $s.SolutionFile.SaveAs("$($env:Temp)\$($s.Name)")
            
            # original = solution store
            # new      = solution dir

            $tpath_orig = "$($env:Temp)\$([Guid]::NewGuid())"
            $tpath_new  = "$($env:Temp)\$([Guid]::NewGuid())"

            New-Item -Path $tpath_orig -ItemType Directory | Out-Null
            New-Item -Path $tpath_new -ItemType Directory | Out-Null

            Expand "$($env:Temp)\$($s.Name)" /f:* $tpath_orig | Out-Null
            Expand "$PWD\$($s.Name)" /f:* $tpath_new | Out-Null

            Compare-Object -ReferenceObject (Get-ChildItem "$($env:Temp)\$id_orig" -Recurse) -DifferenceObject (Get-ChildItem "$($env:Temp)\$id_new" -Recurse)

        }
    }
}

function Test-SPUSolutionNeedReinstall
{
    <#
    TODO
    #>
    param(
        [Microsoft.SharePoint.PowerShell.SPSolutionPipeBind[]]$Identity
    )

    return $false
}

function Test-SPUSolutionDeployed
{
    <#

    .SYNOPSIS
    Tests if the solution is deployed to all the targeted web applications
    .DESCRIPTION
    
    #>
    param(
        [Microsoft.SharePoint.PowerShell.SPSolutionPipeBind[]]$Identity,

        [string[]]$WebApplication = (Get-SPWebApplication | Select -ExpandProperty Url),

        [switch]$AnyWebApplication
    )

    process 
    {
        $Identity | %{

            if(-not (Test-SPUSolutionAdded -Identity $_))
            {
                return $false
            }

            $s = $_.Read()

            if(-not $s.ContainsWebApplicationResource -or $AnyWebApplication)
            {
                return $s.Deployed
            }

            # Create uris for the Deployed applications
            $webAppsUris = ($s.DeployedWebApplications | 
                            Select -ExpandProperty Url | 
                            %{New-Object System.Uri -ArgumentList $_})

            # Create uris for the targeted applications 
            $targetWebAppsUris = ($WebApplication | 
                                  %{New-Object System.Uri -ArgumentList $_})    

            # check if all the targeted webapplications is contained within the 
            # deployed array by doing an intersection then comparing the size to the targeted array
            return $s.Deployed -and ((@($targetWebAppsUris | ?{$webAppsUris -contains $_})).Count -eq (@($targetWebAppsUris)).Count)
            
        }
    }
}

function Test-SPUSolutionAdded
{
    <#

    .SYNOPSIS
    Test if the solution is present in the solution store

    .DESCRIPTION
    Returns true if the solution is present in the solution store. False otherwise.

    #>
    param(
        [Microsoft.SharePoint.PowerShell.SPSolutionPipeBind[]]$Identity
    )

    process
    {
        $Identity | %{
            try 
            {
                $s = $_.Read()
                $true    
            }
            catch 
            {
                $false
            }
        }
    }
}

function Restart-SPUAdministrationService
{
    [CmdletBinding()]
    param(
        [string]$Identity,
        [string]$State
    )

    Write-Host "   => Restarting Administration service" -Foreground Magenta
    Get-Service "SPAdmin*" | Restart-Service
}

function Restart-SPUTimerService
{
    [CmdletBinding()]
    param(
        [string]$Identity,
        [string]$State
    )

    Write-Host "   => Restarting OWSTimer service" -Foreground Magenta
    Get-Service "SPTimer*" | Restart-Service
}


function Restart-SPUApplicationPools
{
    [CmdletBinding()]
    param(
        [string]$Identity,
        [string]$State
    )

    if(@("Deploy") -notcontains $State)
    {
        return
    }

    $appPools = Get-SPSolution -Identity $Identity | 
        %{$_.DeployedWebApplications} | Skip-Null |
        %{$_.ApplicationPool.Name} | 
        Select-Object -Unique

    $appPools | Skip-Null | %{ 
        Write-Host "   => Restarting $_" -Foreground Magenta
        Restart-WebAppPool -Name $_ 
    }
}



