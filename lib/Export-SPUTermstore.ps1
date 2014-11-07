function Export-SPUTermstore
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

    .PARAMETER LiteralPath
    LiteralPath to the xml file to export. If $null, a file with a guid as name
    is created instead.

    .EXAMPLE
    Export the taxonomy group "GroupTest" contained in the "Managed Metadata Service2"
    Get-SPUTermstore "" | Export-SPUTaxonomyGroup -LiteralPath C:\out.xml -GroupName "GroupTest"

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
            ValueFromPipeline = $true,
            Mandatory=$true
        )]
        [Microsoft.SharePoint.Taxonomy.TermStore]$Termstore
    )
    
    $w             = New-Object System.Xml.XmlTextWriter($LiteralPath, $null)
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
    $w.WriteStartElement("SPU")
    $w.WriteStartElement("TermStores")
    $w.WriteStartElement("TermStore")
    $w.WriteAttributeString("Name", $TermStore.Name)
    
    Export-TaxonomyGroups -Groups $allGroups
    
    $w.WriteEndElement()
    $w.WriteEndElement()
    $w.WriteEndElement()
    $w.WriteEndDocument()

    # Complete the file creation
    $w.Flush()
    $w.Close()

}






