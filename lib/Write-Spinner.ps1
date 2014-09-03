function Write-Spinner {
    param(
        [int]$msWait = 0,
        [string]$spinStr = '-\|/. ',
        [char[]]$spinChars = [Char[]] ($spinStr.ToCharArray()),
        [System.Management.Automation.Host.PSHostRawUserInterface]$rawUI = (Get-Host).UI.RawUI,
        [ConsoleColor]$bgColor = $rawUI.BackgroundColor,
        [ConsoleColor]$fgColor = $rawUI.ForegroundColor,
        [System.Management.Automation.Host.Coordinates]$curPos = $rawUI.Get_CursorPosition(),
        [int]$startX = $curPos.X,
        [int]$maxX = $rawUI.WindowSize.Width,
        [switch]$trails
    )

    begin 
    {
        $trailCell = $rawUI.NewBufferCellArray(@($spinChars[-2]), $fgColor, $bgColor)
        $blankCell = $rawUI.NewBufferCellArray(@($spinChars[-1]), $fgColor, $bgColor)

        $spinCells = $spinChars[0..($spinChars.Count - 3)]

        for ($i=0; $i -lt ($spinCells.Count); ++$i) 
        {
            $spinCells[$i] = $rawUI.NewBufferCellArray(@($spinCells[$i]), $fgColor, $bgColor)
        }

        $charNdx =  0
    }

    process 
    {
        if ($charNdx -lt $spinCells.Count)
        {
            $rawUI.SetBufferContents($curPos, $spinCells[$charNdx++]);
        }
        else                                
        { 
            $charNdx = 0
            $rawUI.SetBufferContents($curPos, $trailCell)
            if ($trails) 
            {
                if (++$curPos.X -gt $maxX)  
                { 
                    do 
                    { 
                        --$curPos.X 
                        $rawUI.SetBufferContents($curPos, $blankCell)   
                    } 
                    until($curPos.X -le $startX) 
                }
            }
        }

        Start-Sleep -milliseconds $msWait
        $_
    }

    end {
        
        do 
        { 
            $rawUI.SetBufferContents($curPos, $blankCell)
        }
        until (--$curPos.X -le $startX)
    }
}

<#
function Write-Spinner2
{
    param(
        [switch]$EndOfLine, 
        [switch]$Finished,
        [string]$SpinnerStr = "-\|/."
        [char[]]$SpinnerChars = [char[]]$SpinnerStr.ToCharArray(),
        [ConsoleColor]$bgColor = $Host.UI.RawUI.BackgroundColor,
        [ConsoleColor]$fgColor = $Host.UI.RawUI.ForegroundColor,
    )

    $EscChar = "`r"
    if($EndOfLine){ $EscChar = "`b" }
    if($Finished){ Write-Host "$EscChar"; return; }
    if(!$tickcounter){ Set-Variable -Name "tickcounter" -Scope global -Value 0 -Force -Option AllScope }
    if(!$tickoption){ Set-Variable -Name "tickoption" -Scope global -Value 0 -Force -Option AllScope }
    $chance = Get-Random -Minimum 1 -Maximum 10
    if($chance -eq 5){ if($tickoption -eq 1){$tickoption = 0}else{$tickoption = 1} }
    switch($tickoption){
        0 {
            switch($tickcounter){
                0 { Write-Host "$EscChar|" -NoNewline }
                1 { Write-Host "$EscChar/" -NoNewline }
                2 { Write-Host "$EscChar-" -NoNewline }
                3 { Write-Host "$EscChar\" -NoNewline }
            }
            break;
        }
        1 {
            switch($tickcounter){
                0 { Write-Host "$EscChar|" -NoNewline }
                1 { Write-Host "$EscChar\" -NoNewline }
                2 { Write-Host "$EscChar-" -NoNewline }
                3 { Write-Host "$EscChar/" -NoNewline }
            }
            break;
        }
    }
    if($tickcounter -eq 3){ $tickcounter = 0 }
    else{ $tickcounter++ }
} 
#>