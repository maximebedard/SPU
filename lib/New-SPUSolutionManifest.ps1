function New-SPUSolutionManifest
{
    [CmdletBinding()]
    param(
        [string]$LiteralPath = "$PWD\$([Guid]::NewGuid()).xml",

        [Parameter(
            ValueFromPipeline = $true
        )]
        [Microsoft.SharePoint.PowerShell.SPSolutionPipeBind[]]$Identity = (Get-SPSolution)
    )

    begin 
    { 
        $solutions = @()
    }

    process 
    { 
        $solutions += $Identity
    }

    end 
    {
        $w = New-Object System.Xml.XmlTextWriter $LiteralPath, $null
        $w.Formatting = 'Indented'

        $w.WriteStartDocument()
        $w.WriteStartElement("SPU")
        $w.WriteStartElement("Solutions")
      

        foreach($solutionPipe in $solutions)
        {
            $s = $solutionPipe.Read()

            Write-Verbose "Adding solution $($s.Name) to manifest"

            $w.WriteStartElement("Solution")
            $w.WriteAttributeString("Name", $s.Name)

            if($s.DeployedWebApplications.Count -gt 0)
            {
                $w.WriteStartElement("WebApplications")
                
                foreach($webApp in $s.DeployedWebApplications)
                {
                    $w.WriteStartElement("WebApplication")

                    $w.WriteAttributeString("Url", $webApp.Url)

                    $w.WriteEndElement()
                }

                $w.WriteEndElement()
            }

            $w.WriteEndElement()
        }

        $w.WriteEndElement()
        $w.WriteEndElement()

        $w.WriteEndDocument()

        $w.Flush()
        $w.Close()
    }

}