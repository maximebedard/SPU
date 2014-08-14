if (!(Get-Module WebAdministration)) 
{
    Import-Module WebAdministration -ErrorAction Stop
}

if(!(Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue))
{
    Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop
}

$ScriptRoot = (Split-Path $MyInvocation.MyCommand.Path)
# Import functions
@("$ScriptRoot\src\*.ps1") | 
    Resolve-Path | 
    ?{ -not ($_.ProviderPath.Contains(".Tests.")) } |
    %{ . $_.ProviderPath }

# Utilities
Export-ModuleMember -Function Get-SPUCentralAdministration

# Taxonomy
Export-ModuleMember -Function Import-SPUTaxonomyGroup, Export-SPUTaxonomyGroup, Get-SPUTermstore, Get-SPUTaxonomySession

# Solutions
Export-ModuleMember -Function Export-SPUSolution