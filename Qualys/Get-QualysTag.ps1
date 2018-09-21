function Get-QualysTag{
    <#
        .Synopsis
            Get Qualys Tag(s)

        .DESCRIPTION
            Get Qualys Tag(s)

        .PARAMETER tagID
            ID of a tag

        .PARAMETER searchTerm
            The term you wish to search on. When using the "ruletype" searchfield the approved ruletype verbage are 'STATIC','GROOVY','OS_REGEX','NETWORK_RANGE','NAME_CONTAINS','INSTALLED_SOFTWARE','OPEN_PORTS','VULN_EXIST','ASSET_SEARCH','CLOUD_ASSET'

        .PARAMETER operator
            Operator to apply to searchTerm, options are 'CONTAINS','EQUALS','NOT EQUALS'.  NOTE 'EQUALS' IS case sensative!

        .PARAMETER searchField
            The Search field you would like to search upon.

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER assetCookie
            Use Connect-Qualys to get session cookie with the switch -AssetTagging

        .EXAMPLE
            Get-QualysTag -qualysServer $server -assetCookie $cookie2 -id 123456

            The variables $server is the qualys API Url that you wish to use. The $cookie2 variable is the output captured from Connect-Qualys script using the -AssetTagging switch.

            This will return information on the Qualys tag with the id 123456
        .EXAMPLE
            Get-QualysTag -qualysServer $server -assetCookie $cookie2 -searchField name -operator EQUALS -searchTerm "Testing"

            The variables $server is the qualys API Url that you wish to use. The $cookie2 variable is the output captured from Connect-Qualys script using the -AssetTagging switch.

            This will return information on a tag that matches "Testing" exactly. The script is case sensitive.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory,ParameterSetName='ID')]
        [string]$tagID,

        [Parameter(Mandatory,ParameterSetName='Search')]
        [string]$searchTerm,

        [Parameter(ParameterSetName='Search')]
        [ValidateSet('CONTAINS','EQUALS','NOT EQUALS')]
        [string]$operator = 'CONTAINS',

        [Parameter(ParameterSetName='Search')]
        [ValidateSet('id','name','ruleType')]
        [string]$searchField = 'name',

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$assetCookie
    )

    Begin{}
    Process
    {
        if ($tagID)
        {
            $response = Invoke-RestMethod -Uri "https://$qualysServer/qps/rest/2.0/get/am/tag/$tagID" -Method GET -Headers @{'Content-Type' = 'application/json'} -WebSession $assetCookie
        }
        else{
            #if ruletype validate that it can only be those keywords.
            if($searchField -eq 'ruleType'){
                $Rulelist = 'STATIC','GROOVY','OS_REGEX','NETWORK_RANGE','NAME_CONTAINS','INSTALLED_SOFTWARE','OPEN_PORTS','VULN_EXIST','ASSET_SEARCH','CLOUD_ASSET'
                if(!($Rulelist -contains $searchField)){
                    throw "When using ruleType please use only the sanctioned searchfields. List of search fields for rule type can be found in the help. and here $($Rulelist)"
                }
            }
            [xml]$postdata = '<ServiceRequest>
            <filters>
            <Criteria field="searchField"
           operator="operator">"searchTerm"</Criteria>
            </filters>
           </ServiceRequest>'

            $postdata.ServiceRequest.filters.Criteria.'#text' = "$($searchTerm)"
            $postdata.ServiceRequest.filters.Criteria.operator = "$($operator)"
            $postdata.ServiceRequest.filters.Criteria.field = "$($searchField)"
            $response = Invoke-RestMethod -Headers @{'Content-Type' = 'text/xml'} -Uri "https://$qualysServer/qps/rest/2.0/search/am/tag"  -Method POST -Body $postdata -WebSession $assetCookie
        }
        $response.ServiceResponse.data.Tag
    }
    End{}
}