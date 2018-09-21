function Remove-QualysHostAssetTag{
    <#
        .Synopsis
            Remove tag from a Host Asset

        .DESCRIPTION
            Remove tag from a Host Asset

        .PARAMETER hostID
            ID of a host. The ID of a host can be found using the function Get-QualysHostAsset.

        .PARAMETER tagID
            ID of tag to apply to Host Asset. The ID can be found using the function Get-QualysTag.

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER assetCookie
            Use Connect-Qualys to get session cookie with -AssetTagging for this function to work.

        .EXAMPLE
            Remove-QualysHostAssetTag -qualysServer $server -assetCookie $cookie2 -hostID 12234578 -tagID 987654

            The variables $server is the qualys API Url that you wish to use. The $cookie2 variable is the output captured from Connect-Qualys script using the -AssetTagging switch.

            This function will remove tag 987654 from a host with the ID 12234578.

    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$hostID,

        [Parameter(Mandatory)]
        [string]$tagID,

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$assetCookie
    )

    Begin{}
    Process
    {
        $body = @{ServiceRequest = @{data = @{HostAsset = @{tags = @{remove = @{TagSimple = @{id = $tagID}}}}}}} | ConvertTo-Json -Depth 7
        $response = Invoke-RestMethod -Uri "https://$qualysServer/qps/rest/2.0/update/am/hostasset/$hostID" -Method Post -Headers @{'Content-Type' = 'application/json'} -WebSession $cookie -Body $body
        if ($response.ServiceResponse -eq 'SUCCESS'){
            $Host = Get-QualysHostAsset -hostID $hostID -qualysServer $qualysServer -cookie $cookie
            $success = $Qhost.tags.list.TagSimple | where {$_.id -eq $tagID}
            if($success -eq $null){
                $Host.ServiceResponse.data.HostAsset.ID
            }
        }
        else{
            $response.ServiceResponse.responseErrorDetails.errorMessage
        }
    }
    End{}
}