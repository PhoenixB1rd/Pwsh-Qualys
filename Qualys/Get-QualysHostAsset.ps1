function Get-QualysHostAsset{
    <#
        .Synopsis
            Get Host Asset

        .DESCRIPTION
            Get Host Asset

        .PARAMETER hostID
            ID of a host

        .PARAMETER searchTerm
            part of the name of Host Asset that will be used in a "Contains" search

        .PARAMETER operator
            operator to apply to searchTerm, options are 'CONTAINS','EQUALS','NOT EQUALS'.  NOTE 'EQUALS' IS case sensative!

        .PARAMETER IP
            Get Host Asset by IP address

        .PARAMETER filter
            The search section can take a lot of params, see the Qualys Documentation for details.  us the filter PARAMETER to create your own custom search

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie

        .EXAMPLE
            Get-QualysHostAsset -qualysServer "qualysapi.qualys.com" -cookie $cookie -hostID 123456

            This will return information regarding a specific host.

        .EXAMPLE
            Get-QualysHostAsset -qualysServer "qualysapi.qualys.com" -cookie $cookie -assetID 1234567

            This will return information regarding a specific asset.

        .EXAMPLE
            Get-QualysHostAsset -qualysServer "qualysapi.qualys.com" -cookie $cookie -searchTerm AWS -searchfield tagName -operator EQUALS

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            Use the search parameters to search for assets within the Qualys Cloud. The above example will search for host assets that have a tag name that Equals exactly "AWS".

        .EXAMPLE
            Get-QualysHostAsset -qualysServer "qualysapi.qualys.com" -cookie $cookie -ip 10.0.0.1

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            Can lookup host assets by their IP. Though, it may return more than one host asset if the IP was used for multiple assets.

    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory,ParameterSetName='ID')]
        [string]$hostID,

        [Parameter(Mandatory,ParameterSetName='AssetID')]
        [String]$assetID,

        [Parameter(Mandatory,ParameterSetName='Search')]
        [string]$searchTerm,

        [Parameter(Mandatory,ParameterSetName='Search')]
        [ValidateSet('os','name','activationKey','tagName','agentVersion','lastCheckedIn','lastComplianceScan','lastVulnScan')]
        [String]$searchfield,

        [Parameter(ParameterSetName='Search')]
        [ValidateSet('CONTAINS','EQUALS','NOT EQUALS','GREATER','LESSER')]
        [string]$operator = 'CONTAINS',

        [Parameter(Mandatory,ParameterSetName='ip')]
        [ValidatePattern("\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")]
        [string]$ip,

        [Parameter(Mandatory,ParameterSetName='filter')]
        [System.Collections.Hashtable]$filter,

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie
    )

    Begin{
        [xml]$postdata = '
        <ServiceRequest>
            <filters>
                <Criteria field="name" operator="EQUALS">text</Criteria>
            </filters>
            <preferences>
                <limitResults>500</limitResults>
            </preferences>
        </ServiceRequest>'

        #if using a parameter that is not a date field, like anything other than lastVulnScan or lastComplianceScan, make sure the operator is not 'Greater' or 'Lesser'
        if(($searchfield -notmatch "last*") -and ($operator -eq "GREATER" -or $operator -eq "LESSER")){
            Write-Error "The Operators 'GREATER' and 'LESSER' only work if the SearchField is a date, i.e lastCheckedIn or anything with 'last' in the term."
        }
    }
    Process
    {
        if ($hostID)
        {
            $response = Invoke-RestMethod -Uri "https://$qualysServer/qps/rest/2.0/get/am/hostasset/$hostID" -Method GET -Headers @{'Content-Type' = 'application/json'} -WebSession $cookie
        }
        elseif($assetID){
            $response = Invoke-RestMethod -Uri "https://$qualysServer/qps/rest/2.0/get/am/asset/$assetID" -Method GET -Headers @{'Content-Type' = 'application/json'} -WebSession $cookie
        }
        elseif ($filter)
        {
            $body = $filter | ConvertTo-Json -Depth 5
            $response = Invoke-RestMethod -Uri "https://$qualysServer/qps/rest/2.0/search/am/hostasset" -Method Post -Headers @{'Content-Type' = 'application/json'} -WebSession $cookie -Body $body
        }
        elseif ($ip)
        {
            $postdata.ServiceRequest.filters.Criteria.'#text' = $ip
            $response = Invoke-RestMethod -Uri "https://$qualysServer/qps/rest/2.0/search/am/hostasset" -Method Post -Headers @{'Content-Type' = 'text/xml'} -WebSession $cookie -Body $postdata
        }
        else
        {
            $postdata.ServiceRequest.filters.Criteria.field = $searchfield
            $postdata.ServiceRequest.filters.Criteria.operator = $operator
            $postdata.ServiceRequest.filters.Criteria.'#text' = $searchTerm
            $response = Invoke-RestMethod -Uri "https://$qualysServer/qps/rest/2.0/search/am/hostasset" -Method POST -Headers @{'Content-Type' = 'text/xml'} -WebSession $cookie -Body $postdata
        }

        #build in a while loop to iterate through results that have more than 1000 objects in it. Will need to make a new pscustomobject to aggregate the results.
        if($response.ServiceResponse.hasMoreRecords -ne $null){
            $newobj = @()
            $child = $postdata.CreateElement("startFromID")
            $postdata.ServiceRequest.preferences.AppendChild($child)
            $Propertylist = $obj | Get-Member -MemberType Property | Select-Object -ExpandProperty name
            while($response.ServiceResponse.hasMoreRecords -eq "True"){
                foreach($obj in $response.ServiceResponse.data.HostAsset){
                    $PSObject = New-Object PSObject
                    foreach($Property in $Propertylist){
                        $PSObject | Add-Member NoteProperty $Property $obj.$Property
                    }
                    $newobj += $PSObject
                }

                #change where the results start
                $lastID = $response.ServiceResponse.lastId
                $postdata.ServiceRequest.preferences.startFromID = $lastID

                #make the call again to retrieve more data
                $response = Invoke-RestMethod -Uri "https://$qualysServer/qps/rest/2.0/search/am/hostasset" -Method POST -Headers @{'Content-Type' = 'text/xml'} -WebSession $cookie -Body $postdata
                Write-Host "More results equal $($response.ServiceResponse.hasMoreRecords) total count of the results is $($newobj.count)"
            }
            $newobj
        }
        else{
            $response
        }

    }
    End{}
}