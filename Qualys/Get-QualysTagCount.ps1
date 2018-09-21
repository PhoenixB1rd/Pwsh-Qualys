function Get-QualysTagCount{
    <#
        .Synopsis
            Get-QualysTagCount

        .DESCRIPTION
            Get-QualysTagCount

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER assetCookie
            Use Connect-Qualys to get session cookie

        .EXAMPLE
            Get-QualysTagCount -qualysServer $server -assetCookie $cookie2

            The variables $server is the qualys API Url that you wish to use. The $cookie2 variable is the output captured from Connect-Qualys script using the -AssetTagging switch.

            This will return the total count of tags within the qualys subscription
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

        $response = Invoke-RestMethod -Uri "https://$qualysServer/qps/rest/2.0/count/am/tag" -Method Get -Headers @{'Content-Type' = 'application/json'} -WebSession $cookie
        if ($response.ServiceResponse.count){
            $response.ServiceResponse.count
        }
        else{
            $response.ServiceResponse.responseErrorDetails
        }
    }
    End{}
}