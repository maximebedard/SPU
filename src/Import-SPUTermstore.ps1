Function Import-SPTermstore
{
    param(

        [Parameter( 
            Mandatory=$true,
            Position = 0
        )]
        [Microsoft.SharePoint.PowerShell.SPSitePipeBind]$Site,

        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [string]$Path,

        [Parameter(
            Mandatory = $true,
            Position = 2
        )]
        [string]$TermstoreName
    )

    begin
    {
        [xml]$config = Get-Content $Path -Encoding UTF8 -ErrorAction Stop

        $termstore = Get-SPTermstore $Site $TermstoreName

        Function CreateGroup
        { 
            param(
                [System.Xml.XmlElement]$groupElem
            )

            Write-Host $groupElem.Name -ForeGround Cyan

            $group = $termstore.Groups | ?{ $_.Name -eq $groupElem.Name }
            if(-not $group)
            { 
                $group = $termstore.CreateGroup($groupElem.Name)
            }

            $group.Description = $groupElem.Description

            foreach($termSet in $groupElem.SelectNodes("./TermSets/TermSet"))
            { 
                CreateTermSet $group $termSet
            } 
        }

        Function CreateTermSet
        { 
            param(
                [Microsoft.SharePoint.Taxonomy.Group]$group,
                [System.Xml.XmlElement]$termSetElem
            )

            $termstore.WorkingLanguage = [int]($termSetElem.LCID)

            $guid    = [guid]($termSetElem.ID)
            $termSet = $group.TermSets | ?{ $_.ID -eq $guid } 
            

            if(-not $termSet)
            { 
                $termSet = $group.CreateTermSet($termSetElem.Name, $guid)
            } 

            $termSet.Name        = $termSetElem.Name
            $termSet.Description = $termSetElem.Description


            foreach($term in $termSetElem.SelectNodes("./Terms/Term"))
            { 
                
            }

        } 

        Function CreateTerm
        { 
            param(
                $container,
                [System.Xml.XmlElement]$termElem
            )

            $guid = [guid]($termElem.ID)
            $term = $container.Terms | ?{ $_.ID -eq $guid } 

            if(-not $term)
            { 
                $term = $container.CreateTerm()
            }


        } 

        Function CreateLabel
        { 
        }  



    }

    process
    {
        foreach($group in $config.SelectNodes("/Groups/Group"))
        { 
            CreateGroup $group
        }         
    }

    end
    {
        try {
            $termstore.CommitAll()
        }
        catch {
            $termstore.RollbackAll()
            throw $_
        }

    }

}