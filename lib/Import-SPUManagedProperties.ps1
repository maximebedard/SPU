function Import-SPUManagedProperties
{
    <#
    .SYNOPSIS
    Import SharePoint Managed properties from an XML file

    .DESCRIPTION
    Import the specified managed properties from an XML file. Perform an initial crawl to 
    discover the new fields, then adds all the managed properties and establish the mapping 
    with the newly discovered crawled property.

    .PARAMETER Path
    Path to the xml file to import.

    .PARAMETER SkipCrawl
    Switch to skip the initial crawl

    .INPUTS
    string
    switch

    .OUTPUTS
    $null

    .EXAMPLE
    Import-SPUManagedProperties -Path .\test.xml

    .EXAMPLE
    Import-SPUManagedProperties -Path .\test.xml -SkipCrawl

    #>
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true
        )]
        $SearchApplication = (Get-SPEnterpriseSearchServiceApplication | Select -First 1),

        [Parameter(
            Mandatory = $true
        )]
        [string]$Path,

        [switch]$SkipCrawl,
        [switch]$Confirm
    )

    $types = @{
        "Text"     = 1;
        "Integer"  = 2;
        "Decimal"  = 3;
        "DateTime" = 4;
        "YesNo"    = 5;
        "Binary"   = 6;
        "Double"   = 7;
    }

    [xml]$config = Get-Content $Path -Encoding UTF8 -ErrorAction Stop


    foreach ($crawledPropertyElem in $config.SelectNodes("//CrawledProperty")) 
    {
        $crawledPropertyName        = $crawledPropertyElem.Name
        $crawledPropertyType        = $crawledPropertyElem.DataType
        $crawledPropertyCategory    = $crawledPropertyElem.Category
        $crawledPropertyVariantType = $crawledPropertyElem.VariantType
        $crawledPropertySetId       = $crawledPropertyElem.PropSetId

        $cp = Get-SPEnterpriseSearchMetadataCrawledProperty -SearchApplication $SearchApplication -Name $crawledPropertyName -ErrorAction SilentlyContinue

        if($cp) {
            
            New-SPEnterpriseSearchMetadataCrawledProperty -SearchApplication $SearchApplication -Category $crawledPropertyCategory -VariantType $crawledPropertyVariantType -Name $crawledPropertyName -IsNameEnum $false -PropSet $crawledPropertySetId | Out-Null
        }

        
    }


    foreach ($managedPropertyElem in $config.SelectNodes("//ManagedProperty")) 
    {
        $managedPropName    = $managedPropertyElem.Name
        $managedPropType    = $types[$managedPropertyElem.Type]
        $managedPropMapList = $managedPropertyElem.Map

        # Get existing
        $mp = Get-SPEnterpriseSearchMetadataManagedProperty -SearchApplication $SearchApplication -Identity $managedPropertyElem.Name 
        $mappings = Get-SPEnterpriseSearchMetadataMapping -SearchApplication $SearchApplication -ManagedProperty $mp 

        # Remove mappings
        $mappings | Remove-SPEnterpriseSearchMetadataMapping -Confirm:$Confirm

        # Remove managed property
        $mp | Remove-SPEnterpriseSearchMetadataManagedProperty -Confirm:$Confirm

        # Create new
        New-SPEnterpriseSearchMetadataManagedProperty -SearchApplication $SearchApplication -Name $managedPropName -Type $managedPropType | Out-Null
        
        # Add mappings
        $mp = Get-SPEnterpriseSearchMetadataManagedProperty -SearchApplication $SearchApplication -Identity $managedPropName
        foreach ($mapping in $managedPropertyElem.SelectNodes(".//Mapping")) 
        {
            $mappingCrawledPropertyName = $mapping.CrawledProperty
            $crawledProperty = Get-SPEnterpriseSearchMetadataCrawledProperty -SearchApplication $SearchApplication -Name $mappingCrawledPropertyName
            New-SPEnterpriseSearchMetadataMapping -SearchApplication $SearchApplication -CrawledProperty $crawledProperty -ManagedProperty $mp | Out-Null
        }
    }



}
