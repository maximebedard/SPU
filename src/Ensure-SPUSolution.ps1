Function Ensure-SPUSolution
{ 

    param(
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [string[]]$Path,

        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [ValidateSet("Install", "Uninstall", "Update")]
        $Operation,


        [scriptblock[]]$BeforeDeploy,
        [scriptblock[]]$AfterDeploy,

        [scriptblock[]]$BeforeRetract,
        [scriptblock[]]$AfterRetract,

        [scriptblock[]]$BeforeUpdate,
        [scriptblock[]]$AfterUpdate
    )






} 