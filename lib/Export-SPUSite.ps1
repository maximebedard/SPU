function Export-SPUSite
{

    [CmdletBinding()]
    param(
        [string]$LiteralPath = "$PWD\$([Guid]::NewGuid()).xml",

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Microsoft.SharePoint.PowerShell.SPSitePipeBind[]]$Identity
    )


    begin
    {
        $sitesPipes = @()
    }

    process
    {
        $sitesPipes += $Identity
    }

    end 
    {

        $w             = New-Object System.Xml.XmlTextWriter($LiteralPath, $null)
        $w.Formatting  = 'Indented'
        $w.WriteStartDocument()
        $w.WriteStartElement("SPU")
        $w.WriteStartElement("Sites")

        $sitesPipes | %{
            try 
            {
                $site = $_.Read()
            }
            catch [System.IO.FileNotFoundException]
            {
                Write-Error $_
                continue
            }


            $rootWeb = $site.OpenWeb()

            $w.WriteStartElement("Site")
            $w.WriteAttributeString("Url", $site.Url)
            $w.WriteAttributeString("Title", $site.Title)
            $w.WriteAttributeString("Description", $site.Description)
            $w.WriteAttributeString("Template", "$($rootWeb.WebTemplate)#$($rootWeb.Configuration)")

            $w.WriteEndElement()
                    
            $rootWeb.Dispose()
            $site.Dispose()
        }

        $w.WriteEndElement()
        $w.WriteEndElement()
        $w.WriteEndDocument()

        # Complete the file creation
        $w.Flush()
        $w.Close()

    }




}