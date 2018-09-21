function Set-QualysHostAssetTag{
    <#
        .Synopsis
            Set tag on a Host Asset

        .DESCRIPTION
            Set tag on a Host Asset

        .PARAMETER hostID
            ID of a host. This can be found using the Get-QualysHostAsset function.

        .PARAMETER tagID
            ID of tag to apply to Host Asset. This can be found using the Get-QualysTag function.

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie.

        .EXAMPLE
            Set-QualysHostAssetTag -qualysServer $server -cookie $cookie -hostID 3216545 -tagID 987654

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This fuction will assign tag 987654 to host with the ID 3216545 if either exist.

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
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie
    )

    Begin{
        [xml]$postdata = '
        <ServiceRequest>
            <data>
                <HostAsset>
                    <tags>
                        <add>
                            <TagSimple><id>text</id></TagSimple>
                        </add>
                    </tags>
                </HostAsset>
            </data>
        </ServiceRequest>'
    }
    Process
    {
        $postdata.ServiceRequest.data.HostAsset.tags.add.TagSimple.id = $tagID
        $response = Invoke-RestMethod -Uri "https://$qualysServer/qps/rest/2.0/update/am/hostasset/$hostID" -Method Post -Headers @{'Content-Type' = 'text/xml'} -WebSession $cookie -Body $postdata

        if ($response.ServiceResponse.responseCode -eq 'SUCCESS'){
            $hostID
        }
        else{
            $response.ServiceResponse.responseErrorDetails.errorMessage
        }
    }
    End{}
}