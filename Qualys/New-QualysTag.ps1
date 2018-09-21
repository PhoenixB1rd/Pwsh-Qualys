function New-QualysTag{
    <#
        .Synopsis
            Create New Qualys Tag

        .DESCRIPTION
            Create New Qualys Tag

        .PARAMETER tagName
            Name of a tag to create

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie with the switch -AssetTagging. i.e $cookie2 = Connect-Qualys -qualysServer $server -creds (Get-Credential) -AssetTagging

        .EXAMPLE
            New-QualysTag -qualysServer $server -cookie $cookie -tagName "TESTING"

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This fucntion will check if that tag name is already taken and if it isnt. it will create a tag named "TESTING".

    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory,ParameterSetName='ID')]
        [string]$tagName,

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$assetCookie
    )

    Begin{}
    Process
    {
        ## Validate tag does not already exist

        $response = Get-QualysTag -qualysServer $qualysServer -assetCookie $assetCookie -searchTerm $tagName -operator EQUALS -searchField name

        if($response){
            throw "A Tag with that name already exists: $response"
        }
        else{
            $body = @{ServiceRequest = @{data = @{Tag = @{name = $tagName}}}} | ConvertTo-Json -Depth 5
            $response = Invoke-RestMethod -Uri "https://$qualysServer/qps/rest/2.0/create/am/tag" -Method Post -Headers @{'Content-Type' = 'application/json'} -WebSession $cookie -Body $body
            if ($response.ServiceResponse.responseCode -eq "SUCCESS"){
                return $response.ServiceResponse.data.tag
            }
            else{
                throw $response
            }
        }


    }
    End{}
}