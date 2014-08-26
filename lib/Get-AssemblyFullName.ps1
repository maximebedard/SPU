function Get-AssemblyFullName
{
    param(
        [Parameter(
            Mandatory=$true
        )]
        [string]$Path
    )
	[System.Reflection.AssemblyName]::GetAssemblyName($Path).FullName
}