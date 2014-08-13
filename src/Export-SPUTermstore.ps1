Function Export-SPUTermstore
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
        [Parameter( 
            Position = 0,
            Mandatory = $false,
            ValueFromPipeline = $true
        )]
        [Microsoft.SharePoint.Taxonomy.TermStore]$Termstore = (Get-SPUTermstore),
        
        [string[]]$GroupName, 

        [string]$Path = "$PWD\$([guid]::NewGuid()).xml",

        [switch]$IncludeDeprecated
    )

    $allGroups     = $Termstore.Groups
    if($GroupName)
    { 
        $allGroups = @($allGroups | ?{$_.Name -contains $GroupName})
    }

    $w             = New-Object System.Xml.XmlTextWriter($Path, $null)
    $w.Formatting  = 'Indented'

    $Termstore.WorkingLanguage = $Termstore.DefaultLanguage

    Function Export-TaxonomyGroup
    {
        param(
            [Parameter(
                Mandatory = $true, 
                ValueFromPipeline = $true
            )]
            [Microsoft.SharePoint.Taxonomy.Group[]]$Groups
        )

        begin
        {
            # Groups
            $w.WriteStartElement("Groups")
        }
        process
        {
            foreach($group in $Groups) {
             
                Write-Verbose "Group : $($group.Name)"

                # Group
                $w.WriteStartElement("Group")
                $w.WriteAttributeString("Name", $group.Name)
                $w.WriteAttributeString("Description", $group.Description)

                $group.TermSets | Export-TaxonomyTermSet 

                # End Group
                $w.WriteEndElement()
            
            }
        }
        end
        {
            # End Groups
            $w.WriteEndElement()
        }
    }

    Function Export-TaxonomyTermSet
    {
        param(
            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true
            )]
            [Microsoft.SharePoint.Taxonomy.TermSet]$termSet
        )

        begin
        {
            # TermSets
            $w.WriteStartElement("TermSets")
        }
        process
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

            $termSet.Terms | Export-TaxonomyTerm

            # End TermSet
            $w.WriteEndElement()
        }

        end 
        { 
            # End TermSets
            $w.WriteEndElement()
        }
    }

    Function Export-TaxonomyTerm
    {
        param(
            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true
            )]
            [Microsoft.SharePoint.Taxonomy.Term]$term
        )

        begin 
        {
            # Terms
            $w.WriteStartElement("Terms")
        }

        process 
        {
            # Term
            $w.WriteStartElement("Term")
            $w.WriteAttributeString("ID", $term.Id)
            
            Write-Verbose "Term : $($term.Name)"

            $w.WriteStartElement("Labels")
            foreach($l in $term.Labels)
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


            $w.WriteStartElement("Terms")    
            foreach($t in $term.Terms)
            {
                Export-TaxonomyTerm $t
            }
            $w.WriteEndElement()

            # End Term
            $w.WriteEndElement()
        }
        end 
        {
            $w.WriteEndElement()
        }
    }

    $w.WriteStartDocument()
    
    $allGroups | Export-TaxonomyGroup

    $w.WriteEndDocument()

    # Complete the file creation
    $w.Flush()
    $w.Close()

}






