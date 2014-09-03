function Export-SPUTaxonomyGroup
{
    <#
    .SYNOPSIS
    Export SharePoint Taxonomy Groups to an XML file

    .DESCRIPTION
    Export specified Taxonomy Groups to an XML File. 
    If no groups is specified, all the group contained 
    in the Termstore are exported.

    .PARAMETER GroupName
    An array of taxonomy groups to export. If $null, all the groups
    are exported.

    .PARAMETER Path
    Path to the xml file to export. If $null, a file with a guid as name
    is created instead.

    .PARAMETER IncludeDeprecated
    Boolean to include all deprecated terms or not.

    .INPUTS
    Microsoft.SharePoint.Taxonomy.TermStore
    string[]
    string
    switch

    .OUTPUTS
    $null

    .EXAMPLE

    #>
    [CmdletBinding()]
    param(
        [string]$LiteralPath = "$PWD\$([Guid]::NewGuid()).xml",

        [Parameter(
            Mandatory=$true,
            Position = 1
        )]
        [string[]]$GroupName, 

        [Parameter(
            ValueFromPipeline = $true
        )]
        [Microsoft.SharePoint.Taxonomy.TermStore]$Termstore = (Get-SPUTermstore)
    )
    
    $w             = New-Object System.Xml.XmlTextWriter($Path, $null)
    $w.Formatting  = 'Indented'

    $Termstore.WorkingLanguage = $Termstore.DefaultLanguage

    function Export-TaxonomyGroups
    {
        param(
            [Microsoft.SharePoint.Taxonomy.Group[]]$Groups
        )
    
        # Groups
        $w.WriteStartElement("Groups")
    
        foreach($group in $Groups) 
        {         
            Write-Verbose "Group : $($group.Name)"

            # Group
            $w.WriteStartElement("Group")
            $w.WriteAttributeString("Name", $group.Name)
            $w.WriteAttributeString("Description", $group.Description)

            Export-TaxonomyTermSets -TermSets $group.TermSets 

            # End Group
            $w.WriteEndElement()
        }
    
        # End Groups
        $w.WriteEndElement()
    }

    function Export-TaxonomyTermSets
    {
        param(
            [Microsoft.SharePoint.Taxonomy.TermSet[]]$TermSets
        )
    
        # TermSets
        $w.WriteStartElement("TermSets")
    
        foreach($termSet in $TermSets)
        {
            Write-Verbose "TermSet : $($termSet.Name)"

            # TermSet
            $w.WriteStartElement("TermSet")
            $w.WriteAttributeString("ID", $termSet.Id)

            foreach($language in $Termstore.Languages)
            {
                $Termstore.WorkingLanguage = $language
                # Name
                $w.WriteStartElement("Name")
                
                $w.WriteAttributeString("LCID", $language)
                $w.WriteString($termSet.Name)
                
                # Name
                $w.WriteEndElement()

                # Description
                $w.WriteStartElement("Description")
                
                $w.WriteAttributeString("LCID", $language)
                $w.WriteString($termSet.Description)
                
                # Description
                $w.WriteEndElement()
            } 
            $Termstore.WorkingLanguage = $Termstore.DefaultLanguage

            Export-TaxonomyTerms -Terms $termSet.Terms

            # End TermSet
            $w.WriteEndElement()
        }

        # End TermSets
        $w.WriteEndElement()
    }

    function Export-TaxonomyTerms
    {
        param(
            [Microsoft.SharePoint.Taxonomy.Term[]]$Terms
        )

        # Terms
        $w.WriteStartElement("Terms")

        foreach($term in $Terms)
        {
            Write-Verbose "Term : $($term.Name)"

            # Term
            $w.WriteStartElement("Term")
            $w.WriteAttributeString("ID", $term.Id)
            
            Export-TaxonomyLabels -Labels $term.Labels

            Export-TaxonomyTerms -Term $term.Terms

            # End Term
            $w.WriteEndElement()
        }

        $w.WriteEndElement()
    }

    function Export-TaxonomyLabels
    {
        param(
            [Microsoft.SharePoint.Taxonomy.Label[]]$Labels
        )

        $w.WriteStartElement("Labels")

        foreach($label in $Labels)
        {
            $w.WriteStartElement("Label")
            $w.WriteAttributeString("LCID", $label.Language)
            if($label.IsDefaultForLanguage)
            {
                $w.WriteAttributeString("IsDefaultForLanguage", $label.IsDefaultForLanguage)
            }

            $w.WriteString($label.Value)

            $w.WriteEndElement()
        }
        
        $w.WriteEndElement()    
    }

    $allGroups     = $Termstore.Groups
    if($GroupName)
    { 
        $allGroups = @($allGroups | ?{$_.Name -contains $GroupName})
    }

    $w.WriteStartDocument()
    
    Export-TaxonomyGroups -Groups $allGroups

    $w.WriteEndDocument()

    # Complete the file creation
    $w.Flush()
    $w.Close()

}





