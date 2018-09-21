function New-QualysHostAsset{
    <#
        .Synopsis
            Create New Qualys Asset

        .DESCRIPTION
            Create New Qualys Host Asset
        .PARAMETER assetName
            Host Asset's FQDN to be added
        .PARAMETER tagID
            ID of tag to add at build time
        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie

        .EXAMPLE
            New-QualysHostAsset -qualysServer $server -cookie $cookie -assetName "Newhost" -ip 10.0.0.1 -tagID 123456

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will create a new host asset under that name, NewHost with the IP of 10.0.0.1 with the tag that belongs to the ID of 123456 (not a real tag, only for example purposes).
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$assetName,

        [Parameter(Mandatory)]
        [string]$ip,

        [string]$tagID,

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie
    )

    Begin{}
    Process
    {

        $body = @{ServiceRequest = @{data = @{HostAsset = @{name = $assetName;address=$ip;trackingMethod='IP'}}}}
        if($tagID){$body['ServiceRequest']['data']['HostAsset']['tags'] = @{set=@{TagSimple = @{id = $tagID}}}}
        $body = $body | ConvertTo-Json -Depth 7
        $response = Invoke-RestMethod -Uri "https://$qualysServer/qps/rest/2.0/create/am/hostasset" -Method Post -Headers @{'Content-Type' = 'application/json'} -WebSession $cookie -Body $body
        if ($response.ServiceResponse.responseCode -eq "SUCCESS"){return $response.ServiceResponse.data.HostAsset}
        else{Throw $($response.ServiceResponse.responseErrorDetails.errorMessage)}
    }
    End{}
}