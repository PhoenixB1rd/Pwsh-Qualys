function Stop-QualysScan{
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

        [Parameter(Mandatory=$true)]
        [string]$qualysServer,

        [Parameter(Mandatory=$true)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie,

        [Parameter(Mandatory=$true)]
        [ValidateSet('cancel','pause','resume','delete')]
        [string]$action,

        [Parameter(Mandatory=$true)]
        [string]$refId
    )

    Begin{}
    Process
    {
        $actionbody = @{
            action = $action
            scan_ref = $refId
        }
        $data = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -Uri "https://$qualysServer/api/2.0/fo/scan/" -Method POST -Body $actionbody -WebSession $cookie
        [xml]$xml = $data.SIMPLE_RETURN.RESPONSE.ITEM_LIST.OuterXml
        $object = New-Object PSCustomObject @{
            response = $data.SIMPLE_RETURN.RESPONSE.TEXT
            scanRefID = $xml.ITEM_LIST.InnerText
        }
        $object
    }
    End{}
}