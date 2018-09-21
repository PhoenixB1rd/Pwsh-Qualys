function New-QualysDynamicSearchList {

    <#
        .Synopsis
            Create a new Dynamic Search List based on CVE's or key words and then return the ID of the new Dynamic List created

        .DESCRIPTION
            Find Vulnerable Assets with a specifc CVE or QUID and give the ID of the new list

        .PARAMETER title
            Specify the title for the new searchlist

        .PARAMETER CVE
            A comma seperated list of CVE's in which the Search list is to be built upon

        .PARAMETER keyWord
            A key word to search against the QUI list

        .PARAMETER qualysServer
            Specify the Qualys server to be queried

        .PARAMETER cookie
            Provide the Web Session used to connect to Qualys from the Connect-Qualys command

        .PARAMETER global
            If used the Search list created can be seen by all Qualys users within an organization

        .EXAMPLE
            New-QualysDynamicSearchList -qualysServer $server -cookie $cookie -title "TESTING" -cVE CVE-2018-1234 -global

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will created a new dynamic search list titled TESTING that will search for QID's related to CVE-2018-1234, the Dynamic Search list will be global and available to everyone.

        .EXAMPLE
            New-QualysDynamicSearchList -qualysServer $server -cookie $cookie -title "ILO" -keyword "HP ILO"

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will look for QIDs that involve HP ILOs if they exist with the title "ILO", with no global flag, only the creator will be able to see the searchlist and those with `
            manager access.

    #>
    [CmdletBinding(DefaultParameterSetName= 'CVE')]
    Param
    (

        [Parameter(Mandatory)]
        [string]$title,

        [Parameter(ParameterSetName='CVE')]
        [string[]]$cVE,

        [Parameter(ParameterSetName='KeyWord')]
        [string]$keyWord,

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie,

        [Parameter()]
        [switch]$global
    )

    Begin{}
    Process
    {
        if($global){
            [int]$global = 1
        }
        else {
            [int]$global = 0
        }

        $actionBody = @{
            action = 'create'
            title = $title
            global = $global
        }
        if($cVE){
            $actionBody.add("cve_ids",($cVE -join ","))
        }
        else {
            $actionBody.add("vuln_title",$keyWord)
        }
        [xml]$response = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -URI "https://$qualysServer/api/2.0/fo/qid/search_list/dynamic/" -Method Post -WebSession $cookie -Body $actionBody
        $IDtag = $response.SIMPLE_RETURN.RESPONSE.ITEM_LIST.ITEM.Value
        if($IDtag -ne $null){
            $IDtag
        }
        else{
            $response.SIMPLE_RETURN.RESPONSE.TEXT
        }

    }
    End{}
}