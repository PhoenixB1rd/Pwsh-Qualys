function Invoke-QualysBase{
    <#
        .Synopsis
            Not currently useable
        .DESCRIPTION

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie

    #>
    [CmdletBinding()]
    Param
    (

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie
    )

    Begin{}
    Process
    {
        $actionbody = @{
            #insert actions here
        }
        return (Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -Uri "https://$qualysServer/api/2.0/fo/" -Method GET -Body $actionbody -WebSession $cookie)
    }
    End{}
}