function Remove-QualysIP{
    <#
        .Synopsis
            Remove IP from an asset group using the asset Group ID, which can be found by Get-QualysAssetGrp

        .DESCRIPTION
            Remove IP from an asset group using the asset Group ID, which can be found by Get-QualysAssetGrp

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie

        .PARAMETER ip
            The Ip that you wish to remove from an asset group.

        .PARAMETER groupID
            The ID of the Asset group that you wish to remove IPs from.

        .EXAMPLE
            Remove-QualysIp -qualysServer $server -cookie $cookie -ip 10.23.42.12 -groupID 2315643

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This function will remove ip 10.23.42.12 from asset group 2315643. Asset group ID can be found using Get-QualysAssetGrp.
    #>
    [CmdletBinding()]
    Param
    (
        [ValidatePattern("\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")]
        [string]$ip,

        [Parameter(Mandatory)]
        [string]$groupID,

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie
    )

    Begin{}
    Process
    {
        $actionBody = @{
            action = "edit"
            id = $groupID
            remove_ips = $ip
        }
        [xml]$returnedXML = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -Uri "https://$qualysServer/api/2.0/fo/asset/group/" -Method Post -Body $actionBody -WebSession $cookie
        if ($returnedXML.SIMPLE_RETURN.RESPONSE.TEXT -ne "Asset Group Updated Successfully"){
            throw $returnedXML.SIMPLE_RETURN.RESPONSE.TEXT
        }
        else{
            return $returnedXML.SIMPLE_RETURN.Response
        }
    }
    End{}
}