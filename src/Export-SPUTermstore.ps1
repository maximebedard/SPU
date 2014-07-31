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

    begin
    {
        $allGroups         = $Termstore.Groups
        if($GroupName)
        { 
            $allGroups     = @($allGroups | ?{$_.Name -contains $GroupName})
        }

        $writer            = New-Object System.Xml.XmlTextWriter($Path, $null)
        $writer.Formatting = 'Indented'

        Function WriteGroup
        {
            param(
                [Microsoft.SharePoint.Taxonomy.Group]$group
            )

            Write-Verbose "$($group.Name)"

            # Group
            $writer.WriteStartElement("Group")
            $writer.WriteAttributeString("Name", $group.Name)
            $writer.WriteAttributeString("Description", $group.Description)

            # TermSets
            $writer.WriteStartElement("TermSets")

            foreach($language in $Termstore.Languages)
            {
                
                $Termstore.WorkingLanguage = $language 
                $writer.WriteComment("Language : $language")
                foreach($termSet in $group.Termsets)
                {
                    WriteTermset $termSet
                }

            }

            # End TermSets
            $writer.WriteEndElement()

            # End Group
            $writer.WriteEndElement()
        }

        Function WriteTermset
        {
            param(
                [Microsoft.SharePoint.Taxonomy.TermSet]$termSet
            )

            Write-Verbose "  $($termSet.Name)"

            # TermSet
            $writer.WriteStartElement("TermSet")
            $writer.WriteAttributeString("ID", $termSet.Id)
            $writer.WriteAttributeString("Name", $termSet.Name)
            $writer.WriteAttributeString("Description", $termSet.Description)
            $writer.WriteAttributeString("LCID", $Termstore.WorkingLanguage)

            # Terms
            $writer.WriteStartElement("Terms")
            
            foreach($term in $termSet.Terms)
            {
                WriteTerm $term
            }

            $writer.WriteEndElement()

            # End TermSet
            $writer.WriteEndElement()
        }

        Function WriteTerm
        {
            param(
                [Microsoft.SharePoint.Taxonomy.Term]$term
            )

            Write-Verbose "    $($term.Name)"

            # Term
            $writer.WriteStartElement("Term")
            $writer.WriteAttributeString("ID", $term.Id)
            $writer.WriteAttributeString("Name", $term.Name)
            
            $writer.WriteStartElement("Terms")    
            foreach($t in $term.Terms)
            {
                WriteTerm $t
            }
            $writer.WriteEndElement()

            $writer.WriteStartElement("Labels")
            foreach($l in ($term.Labels | 
                ?{ $_.Language -eq $Termstore.WorkingLanguage }))
            {
                WriteLabel $l
            }
            $writer.WriteEndElement()

            # End Term
            $writer.WriteEndElement()
        }

        Function WriteLabel
        {
            param(
                [Microsoft.SharePoint.Taxonomy.Label]$label
            )

            $writer.WriteStartElement("Label")

            $writer.WriteAttributeString("Value", $label.Value)
            $writer.WriteAttributeString("IsDefaultForLanguage", $label.IsDefaultForLanguage)

            $writer.WriteEndElement()
        }

        $writer.WriteStartDocument()
        
    }

    process
    {
        # Groups
        $writer.WriteStartElement("Groups")

        foreach($group in $allGroups)
        {
            WriteGroup $group
        }

        # End Groups
        $writer.WriteEndElement()
    }

    end 
    {
        $writer.WriteEndDocument()

        # Complete the file creation
        $writer.Flush()
        $writer.Close()

        # Dispose the SPSite
        if($site) { $site.Dispose() }
    }

}






