function Get-QualysDynamicSearchList{
    <#
        .Synopsis
            Find Vulnerable Assets with a specifc CVE or QUID

        .DESCRIPTION
            Find Vulnerable Assets with a specifc CVE or QUID

        .PARAMETER qualysServer
            Specify the Qualys server to be queried

        .PARAMETER cookie
            Provide the Web Session used to connect to Qualys from the Connect-Qualys command

        .PARAMETER id
            ID of the Dynamic Search List that you wish to query, if not specified it will return a large list.

        .EXAMPLE
            Get-QualysDynamicSearchlist -qualysServer $server -cookie $cookie -id 123456

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            Will return information on the Dynamic Searclist with ID 123456 inlcuding QIDs associated, owner and any templates that are using that dynamic searchlist.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie,

        [Parameter()]
        [string]$id = "1000000-10000000"

    )

    Begin{}
    Process
    {
        $actionBody = @{
            action = "list"
            ids = $id
        }
        #calling all dynamic lists since there is not api functionality to search or grab a specific ID
        [xml]$xmlResponse = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -URI "https://$qualysServer/api/2.0/fo/qid/search_list/dynamic/" -Method Get -WebSession $cookie -Body $actionBody
        [System.Xml.XmlElement]$root = $xmlResponse.get_DocumentElement()
        $data = $root.RESPONSE.DYNAMIC_LISTS.DYNAMIC_LIST
        $data
        #in the future would like to clean-up the data to a pscustom object instead of the nested xml version that is currently outputted.
    }
    End{}
}