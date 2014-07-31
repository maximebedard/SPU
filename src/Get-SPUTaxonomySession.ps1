Function Get-SPUTaxonomySession
{
    <#
    .SYNOPSIS
    Get a SharePoint TaxonomySession Object

    .DESCRIPTION
    Returns a Microsoft.SharePoint.Taxonomy.TaxonomySession. If no site 
    collection is passed, the Central Administration site collection
    is used.

    .PARAMETER Site
    Site collection object to use when retreiving the taxonomy session.

    .INPUTS
    Microsoft.SharePoint.PowerShell.SPSitePipeBind

    .OUTPUTS
    Microsoft.SharePoint.Taxonomy.TaxonomySession

    .EXAMPLE
    Returns a taxonomy session using the central administration site collection
    $session = Get-SPUTaxonomySession

    .EXAMPLE
    Returns a taxonomy session using a custom site collection
    $session = Get-SPUTaxonomySession -Site "http://portal"

    .EXAMPLE
    Returns a site collection Piping an SPSite object
    $session = (Get-SPSite "http://portal" | Get-SPUTaxonomySession)

    .LINK
    http://msdn.microsoft.com/en-us/library/microsoft.sharepoint.taxonomy.taxonomysession(v=office.14).aspx
    
    #>
    Param(
        [Parameter(
            Position = 0,
            Mandatory = $false, 
            ValueFromPipeline = $true
        )]
        [Microsoft.SharePoint.PowerShell.SPSitePipeBind]$Site = (Get-SPUCentralAdministration).Url
    )

    Get-SPTaxonomySession -Site $Site
}