function Disconnect-Qualys {
    <#
        .Synopsis
           Disconnect Qaulys API Session, this only works on the old API

        .DESCRIPTION
             Disconnect Qaulys API Session, this only works on the old API

        .PARAMETER qualysServer
                FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie

        .EXAMPLE
            disconnect-Qualys -uri 'https://qualysapi.qualys.com:443/api/2.0/fo/session/' -header (Get-QualysHeader)

        .Notes
            Author: Travis Sobeck
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
            ## Login/out
            $logInBody = @{action = "logout"}
            $return = (Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -Uri "https://$qualysServer/api/2.0/fo/session/" -Method Post -Body $logInBody -WebSession $cookie).SIMPLE_RETURN.RESPONSE.TEXT
            if ($return -eq 'Logged out'){return $return}
            else{Write-Warning "Qualys logout issue" + $return}
        }
        End{}
    }