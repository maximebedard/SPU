if (!(Get-Module WebAdministration)) 
{
    Import-Module WebAdministration -ErrorAction Stop
}

if(!(Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue))
{
    Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop
}

$ScriptRoot = (Split-Path $MyInvocation.MyCommand.Path)

# Custom filters
filter Skip-Null { $_ | ?{ $_ } }

# Import cmdlets
@("$ScriptRoot\lib\*.ps1") | 
    Resolve-Path | 
    ?{ -not ($_.ProviderPath.Contains(".Tests.")) } |
    %{ . $_.ProviderPath }

# Sharepoint Utilities
Export-ModuleMember -function Get-SPUCentralAdministration

# Taxonomy
Export-ModuleMember -function Import-SPUTermstore, 
    Export-SPUTermstore, 
    Get-SPUTermstore, 
    Get-SPUTaxonomySession

# Solutions
Export-ModuleMember -function Export-SPUSolution, 
    New-SPUSolutionManifest, 
    Import-SPUSolution, 
    Test-SPUSolutionDeployed, 
    Test-SPUSolutionAdded,
    Compare-SPUSolutionFile

# General Utilities
Export-ModuleMember -function Get-AssemblyFullName, 
    Write-Spinner, 
    Compare-Directory

# Sites

Export-ModuleMember -function Export-SPUSite