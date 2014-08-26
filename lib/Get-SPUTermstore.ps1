function Get-SPUTermstore
{
    <#
    .SYNOPSIS
    Get a SharePoint Termstore Object

    .DESCRIPTION
    Returns a Microsoft.SharePoint.Taxonomy.TermStore. If no taxonomy session 
    is passed, a default one is used. The termtore can either be retreived by
    name or by id. If none specified, the default termstore is return, null if
    non existant.

    .PARAMETER Session
    A Microsoft.SharePoint.Taxonomy.Session object. See Get-SPUTaxonomySession.

    .PARAMETER Name
    Name of the termstore

    .PARAMETER ID
    ID of the termstore

    .INPUTS
    Microsoft.SharePoint.Taxonomy.TaxonomySession
    System.String
    or 
    Microsoft.SharePoint.Taxonomy.TaxonomySession
    System.Guid
    or 
    Microsoft.SharePoint.Taxonomy.TaxonomySession

    .OUTPUTS
    Microsoft.SharePoint.Taxonomy.TermStore

    .EXAMPLE
    TODO
    
    .EXAMPLE
    TODO
    
    .EXAMPLE
    TODO

    .LINK
    http://msdn.microsoft.com/en-us/library/microsoft.sharepoint.taxonomy.termstore(v=office.14).aspx
    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    Param(
        [Parameter(
            Mandatory=$false, 
            ValueFromPipeline=$true
        )]
        [Microsoft.SharePoint.Taxonomy.TaxonomySession]$Session = $(Get-SPUTaxonomySession),

        [Parameter(
            Position = 0,
            Mandatory=$true, 
            ParameterSetName="ByName"
        )]
        [string]$Name,

        [Parameter(
            Position = 0,
            Mandatory=$true, 
            ParameterSetName="ById"
        )]
        [guid]$Id
    )

    switch($PsCmdlet.ParameterSetName)
    {
        "ByName" {
            $Identity = $Name
        }

        "ById" {
            $Identity = $Id
        }

        "Default" {
            $Identity = $Session.DefaultSiteCollectionTermStore.Id
        }
    }

    $Session.TermStores[$Identity]
}