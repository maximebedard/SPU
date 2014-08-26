if (!(Get-Module WebAdministration)) 
{
    Import-Module WebAdministration -ErrorAction Stop
}

if(!(Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue))
{
    Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop
}

$ScriptRoot = (Split-Path $MyInvocation.MyCommand.Path)

# Import cmdlets
@("$ScriptRoot\lib\*.ps1") | 
    Resolve-Path | 
    ?{ -not ($_.ProviderPath.Contains(".Tests.")) } |
    %{ . $_.ProviderPath }

# Utilities
Export-ModuleMember -function Get-SPUCentralAdministration

# Taxonomy
Export-ModuleMember -function Import-SPUTaxonomyGroup, Export-SPUTaxonomyGroup, Get-SPUTermstore, Get-SPUTaxonomySession

# Solutions
Export-ModuleMember -function Export-SPUSolution

Export-ModuleMember -function Get-AssemblyFullName