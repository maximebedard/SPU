Function Import-SPUTermstore
{
    param(
        [Parameter( 
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Microsoft.SharePoint.Taxonomy.TermStore]$TermStore,

        [Parameter(
            Mandatory = $true
        )]
        [string]$Path
    )

    [xml]$config = Get-Content $Path -Encoding UTF8 -ErrorAction Stop

    Function Import-TaxonomyGroup
    { 
        param(
            [System.Xml.XmlElement]$groupElem
        )

        $group = $TermStore.Groups | ?{ $_.Name -eq $groupElem.Name }
        if(-not $group)
        { 
            $group = $TermStore.CreateGroup($groupElem.Name)
        }

        $group.Description = $groupElem.Description

        foreach($termSet in $groupElem.SelectNodes("./TermSets/TermSet"))
        { 
            Import-TaxonomyTermSet $group $termSet
        } 
    }

    Function Import-TaxonomyTermSet
    { 
        param(
            [Microsoft.SharePoint.Taxonomy.Group]$group,
            [System.Xml.XmlElement]$termSetElem
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
            Import-TaxonomyTerm $termSet $term
        }

    } 

    Function Import-TaxonomyTerm
    { 
        param(
            $container,
            [System.Xml.XmlElement]$termElem
        )

        $guid   = [guid]($termElem.ID)
        $term   = $container.Terms | ?{ $_.ID -eq $guid } 

        $labels = $termElem.SelectNodes("./Labels/Label")
        $terms  = $termElem.SelectNodes("./Terms/Term")

        if(-not $term)
        {
            $name = ($labels | ?{ $_.LCID -eq $TermStore.DefaultLanguage -and $_.IsDefaultForLanguage })."#text"
            if(-not $name)
            { 
                throw "The Term's default label name for the LCID $($TermStore.DefaultLanguage) is missing."
            } 
            $term = $container.CreateTerm($name, $TermStore.WorkingLanguage, $termElem.ID)
        }

        foreach($label in $labels)
        {
            $term.CreateLabel($label."#text", $label.LCID, $label.IsDefaultForLanguage)
        }

        foreach($term2 in $terms)
        {
            Import-TaxonomyTerm $term $term2 
        }
    } 


    foreach($group in $config.SelectNodes("/Groups/Group"))
    { 
        Import-TaxonomyGroup $group
    }         

    try 
    {
        $TermStore.CommitAll()
    }
    catch 
    {
        $TermStore.RollbackAll()
        throw $_
    }

}