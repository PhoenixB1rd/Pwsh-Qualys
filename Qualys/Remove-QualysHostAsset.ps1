function Remove-QualysHostAsset{
    <#
        .Synopsis
            Remove Qualys Host Asset

        .DESCRIPTION
            Remove New Qualys Host Asset

        .PARAMETER assetID
            Host Asset's ID

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in

        .PARAMETER assetCookie
            Use Connect-Qualys to get session cookie with -AssetTagging for this function to work.

        .PARAMETER tagName
            Use the tagName variable to delete all assets with the tag name specified. The tag name is case sensitive and must match EXACTLY.

        .EXAMPLE
            Remove-QualysHostAsset -qualysServer $server -assetCookie $cookie2 -assetID 123456789

            The variables $server is the qualys API Url that you wish to use. The $cookie2 variable is the output captured from Connect-Qualys script using the -AssetTagging switch.

            This function will remove the asset 123465789.

        .EXAMPLE
            Remove-QualysHostAsset -qualysServer $server -assetCookie $cookie2 -tagName "To Be Deleted"

            The variables $server is the qualys API Url that you wish to use. The $cookie2 variable is the output captured from Connect-Qualys script using the -AssetTagging switch.

            This function will remove all hosts underneath the tag "To Be Deleted". Note that the parameter tagName is case sensitive and will need to match exactly.

    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(ParameterSetName = "AssetID")]
        [string]$assetID,

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$assetCookie,

        [Parameter(ParameterSetName = "Tag")]
        [String]$tagName
    )

    Begin{
        if($TagID){
            [xml]$postdata = "
            <ServiceRequest>
                <filters>
                    <Criteria field='tagName' operator='EQUALS'>$($tagName)</Criteria>
                </filters>
            </ServiceRequest>"
        }
        else{
            [xml]$postdata = "
            <ServiceRequest>
                <filters>
                    <Criteria field='trackingMethod' keyword='Instance_ID'>$($assetID)</Criteria>
                </filters>
            </ServiceRequest>"
        }

    }
    Process
    {
        Invoke-RestMethod -Uri "https://$qualysServer/qps/rest/2.0/delete/am/hostasset" -Method POST -Headers @{'Content-Type' = 'text/xml'} -WebSession $assetCookie -Body $postdata

    }
    End{}
}