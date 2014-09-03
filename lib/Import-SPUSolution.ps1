function Import-SPUSolution
{
    <#

        .SYNOPSIS
        Import all the solution within a specific manifest into SharePoint.

        .DESCRIPTION
        Import all the solution, deploys or update existing solutions according to a 
        solution manifest. The manifest has the following structure : 

        c:\my_app\TestA.wsp
        c:\my_app\TestB.wsp
        c:\my_app\manifest.xml

        <?xml version="1.0"?>
        <Solutions>
          <Solution Name="TestA.wsp" />
          <Solution Name="TestB.wsp" >
            <WebApplications>
              <WebApplication Url="http://my_webbapp" />
            </WebApplications>
          </Solution>
        </Solutions>

        .PARAMETER Path
        Path to the folder containing the manifest or the manifest itself

        .PARAMETER BeforeCallback
        Callbacks called before any operation is executed. Usually environnement preparation
        or presesquisites. This callback takes no parameters.

        .PARAMETER AfterCallback
        Callbacks called after all operation is executed. This callback takes no parameters.

        .PARAMETER BeforeActionCallback
        Callbacks called each time before an operation is executed for a specific solution. 
        This callback takes 2 parameters : $Identity and $State. 

        .PARAMETER Parameters
        Callbacks called each time after an operation is executed for a specific solution. 
        This callback takes 2 parameters : $Identity and $State.

        .PARAMETER Cleanup
        Switch to specified if the solution contained in the manifest must be remove from SharePoint.

        .EXAMPLE 
        To import all the solution contained within the manifest.xml
        PS C:\> Import-SPUSolution -Path c:\my_app
        or
        PS C:\> Import-SPUSolution -Path c:\my_app\manifest.xml

        .EXAMPLE
        To remove all the solutions according to a manifest
        PS C:\> Import-SPUSolution -Path c:\my_app -Cleanup

        .EXAMPLE
        To add a step into the deployment process. The following reset IIS after every solution deployed.
        PS C:\> Import-SPUSolution -Path c:\my_app -BeforeActionCallback { param($Identity, $State) if($state -eq "Deploy") {IISReset} }
    #>
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

                # We check if the solution is not newly added
                if($PreviousState -ne "Add")
                {
                    $s = $Identity.Read()

                    $reff_wsp = "$($env:Temp)\$($s.Name)"
                    $diff_wsp = "$PWD\$($s.Name)"

                    # Save the currently used solution file in temp folder
                    $s.SolutionFile.SaveAs("$reff_wsp")

                    # Compare both solution files
                    $compare = Compare-SPUSolutionFile $reff_wsp $diff_wsp

                    # diff contains feature.xml or manifest.xml = reinstall 
                    if($compare | ?{ ($_.Item -like "feature.xml") -or ($_.Item -like "manifest.xml") }) 
                    {
                        return "Retract"
                    }

                    # diff contains other stuff than dll = update it!
                    #if()
                    #{
                    #    return "Update"
                    #}

                    # diff contains only dll = check dates
                    # Update if modified date of fs > deployed
                    #if()
                    #{
                    #    return "Update"
                    #}

                    # diff contains only dll, check if the deployed one modified date > to deploy

                    # do nothing, the solution is most likely the most recent one. may deploy it to another webapp?
                }

                if(-not (Test-SPUSolutionDeployed -Identity $Identity -WebApplication $WebApplication))
                {
                    return "Deploy"
                }
                
                return "Installed"
            }
        
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



