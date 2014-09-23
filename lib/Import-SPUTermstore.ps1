function Import-SPUTermstore
{
    <#
    .SYNOPSIS
    Import SharePoint Taxonomy Groups from an XML file

    .DESCRIPTION
    Import specified Taxonomy Groups from an XML File.
    This cmdlet import the following elements : Groups, TermSets, Terms
    and labels. 

    .PARAMETER TermStore
    A Microsoft.SharePoint.Taxonomy.TermStore object of the specified
    termstore to import all the terms.

    .PARAMETER Path
    Path to the xml file to import.

    .INPUTS
    Microsoft.SharePoint.Taxonomy.TermStore
    string

    .OUTPUTS
    $null

    .EXAMPLE
    Get-SPUTermstore -Name "Managed Metadata Service" | Import-SPUTermstore -Path .\test.xml

    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true
        )]
        [string]$Path
    )

    [xml]$config = Get-Content $Path -Encoding UTF8 -ErrorAction Stop 

    function Import-TaxonomyTermStore
    {
        param(
            [System.Xml.XmlElement]$termStoreElem
        )
    
        $termstore = Get-SPUTermstore -Name $termStoreElem.Name -ErrorAction "Stop"

        foreach($group in $termStoreElem.SelectNodes("./Groups/Group"))
        {
            try 
            {
                Import-TaxonomyGroup $group $termstore
                $termStore.CommitAll()
            }
            catch 
            {
                $termStore.RollbackAll()
                throw $_
            }
        }
    }

    function Import-TaxonomyGroup
    { 
        param(
            [System.Xml.XmlElement]$groupElem,
            [Microsoft.SharePoint.Taxonomy.TermStore]$TermStore
        )

        $group = $TermStore.Groups | ?{ $_.Name -eq $groupElem.Name }
        if(-not $group)
        { 
            $group = $TermStore.CreateGroup($groupElem.Name)
        }

        $group.Description = $groupElem.Description

        foreach($termSet in $groupElem.SelectNodes("./TermSets/TermSet"))
        { 
            Import-TaxonomyTermSet $group $termSet $TermStore
        } 
    }

    function Import-TaxonomyTermSet
    { 
        param(
            [Microsoft.SharePoint.Taxonomy.Group]$group,
            [System.Xml.XmlElement]$termSetElem,
            [Microsoft.SharePoint.Taxonomy.TermStore]$TermStore
        )

        $guid         = [guid]($termSetElem.ID)
        $termSet      = $group.TermSets | ?{ $_.ID -eq $guid } 

        $names        = $termSetElem.SelectNodes("./Name")
        $descriptions = $termSetElem.SelectNodes("./Description")
        $terms        = $termSetElem.SelectNodes("./Terms/Term")
        
        if(-not $termSet)
        { 
            $name = ($names | ?{ $_.LCID -eq $TermStore.DefaultLanguage })."#text"
            if(-not $name)
            { 
                throw "The TermSet name for the LCID $($TermStore.DefaultLanguage) is missing."
            } 
            $termSet = $group.CreateTermSet($name, $guid)
        } 

        # We set the names for all the available locales
        foreach($name in $names)
        { 
            $TermStore.WorkingLanguage = $name.LCID
            $termSet.Name = $name."#text"
        } 
        $TermStore.WorkingLanguage = $TermStore.DefaultLanguage

        # We set the description for all the available locales
        foreach($description in $descriptions)
        { 
            $TermStore.WorkingLanguage = $description.LCID
            $termSet.Description = $description."#text"
        }
        $TermStore.WorkingLanguage = $TermStore.DefaultLanguage

        # Create all the terms in the current TermSet
        foreach($term in $terms)
        { 
            Import-TaxonomyTerm $termSet $term $TermStore
        }
    } 

    function Import-TaxonomyTerm
    { 
        param(
            $container,
            [System.Xml.XmlElement]$termElem,
            [Microsoft.SharePoint.Taxonomy.TermStore]$TermStore
        )

        $guid   = [guid]($termElem.ID)
        $term   = $container.Terms | ?{ $_.ID -eq $guid } 

        $labels = $termElem.SelectNodes("./Labels/Label")
        $terms  = $termElem.SelectNodes("./Terms/Term")

        $defaultLabel = ($labels | ?{ $_.LCID -eq $TermStore.DefaultLanguage -and $_.IsDefaultForLanguage })
        if(-not $defaultLabel)
        {
            throw "The Term's default label for the LCID $($TermStore.DefaultLanguage) is missing."
        } 

        if(-not $term)
        {
            $term = $container.CreateTerm($defaultLabel."#text", $TermStore.WorkingLanguage, $termElem.ID)
        }

        foreach($label in $labels)
        {
            # Check if the label doesn't exists
            if(-not ($term.Labels | ?{ ($_.Language -eq $label.LCID) -and ($_.Value -eq $label."#text") }))
            { 
                $term.CreateLabel($label."#text", $label.LCID, $label.IsDefaultForLanguage) | Out-Null
            } 
        }

        foreach($cTerm in $terms)
        {
            Import-TaxonomyTerm $term $cTerm $TermStore
        }
    } 

    foreach($termstore in $config.SelectNodes("//TermStore"))
    { 
        Import-TaxonomyTermStore $termstore
    }         
    
}