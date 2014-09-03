function Get-SPUCentralAdministration
{
    <#
    .SYNOPSIS
    Get a SharePoint Central Administration Web Application

    .DESCRIPTION
    Returns a Microsoft.SharePoint.Administration.WebApplication object
    for the central administration.

    .INPUTS
    None 

    .OUTPUTS
    Microsoft.SharePoint.Administration.WebApplication

    .EXAMPLE
    Returns the central administration web application
    $ca = Get-SPCentralAdministration
    
    #>
    Get-SPWebApplication -IncludeCentralAdministration | 
        ?{$_.IsAdministrationWebApplication} |
        Select -First 1	
}
