function New-QualysOptionProfile{

    <#
        .Synopsis
            Create a new Qualys Option Profile to then be imported into Qualys to run custom scans

        .DESCRIPTION
            Create a new Qualys Option Profile to then be imported into Qualys to run custom scans

        .PARAMETER TemplateDoc
            Import the XML template doc for the option profile. One is provided in the module and is labeled OptionProfileTemplate.xml

        .PARAMETER qualysServer
            Specify the Qualys server to be queried

        .PARAMETER cookie
            Provide the Web Session used to connect to Qualys from the Connect-Qualys command

        .PARAMETER name
            Provide a name for the option profile. Import will not work if there is no name.

        .PARAMETER subscriptionID
            Provide the Qualys Subscription ID. This can easily be found by doing an export of Option profiles in which the subscript ID can be seen in the results.

        .PARAMETER global
            Switch that will import the option profile as a globally used script or not if the switch is not added.

        .PARAMETER portScanType
            Can onlye be "None","Full", "Standard" or "Light". If "None" is chosen please provide a list of ports in the ports parameter

        .PARAMETER ports
            Specify specific ports that you want Qualys to scan.

        .PARAMETER searchlistID
            Please Supply the search list ID to be associated with the option profile. This is not required, but if you choose this option you will also need to provide the dynamic search list name.

        .PARAMETER searchlistName
            Supply the Searchlist name that is associated with the above search list ID.

        .EXAMPLE
            New-QualysOptionProfele -qualysServer $server -cookie $cookie -templateDoc ./Documents/Github/Qualys-Powershell/Qualys/OptionProfileTemplate.xml -name "Testing" -subscriptionID 1233456 -portScanType Standard `
            -searchlistID 654321 -searchlistName "TestSearchList"

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            The above command will create a new option profile named Testing. The output will reflect the name and ID of the option profile.

    #>

    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$templateDoc,

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie,

        [Parameter(Mandatory)]
        [string]$name,

        [Parameter(Mandatory)]
        [string]$subscriptionID,

        [Parameter()]
        [switch]$global,

        [Parameter(Mandatory)]
        [ValidateSet("none","full","standard","light")]
        [string]$portScantype = "standard",

        [Parameter()]
        [string[]]$ports,

        [Parameter(ParameterSetName='search')]
        [int]$searchListID,

        [Parameter(ParameterSetName='search')]
        [string]$searchlistName

    )

    Begin{}
    Process
    {
        $XMLdoc =[xml](Get-Content $templatedoc)
        $root = $xmldoc.OPTION_PROFILES.OPTION_PROFILE

        #Group Name
        $root.BASIC_INFO.GROUP_NAME.'#cdata-section' = "$name"

        #Subscription ID
        $root.BASIC_INFO.SUBSCRIPTION_ID = $subscriptionID

        #Is global?
        if ($global){
            $root.BASIC_INFO.IS_GLOBAL = 1
        }
        else{
            $root.BASIC_INFO.IS_GLOBAL = 0
        }
        #ports = None, Full, Standard or light
        $root.SCAN.PORTS.TCP_PORTS.TCP_PORTS_TYPE = "$portScantype"

        #Are there addtional ports  and are they in a CSV format
        if($ports){
            $root.SCAN.PORTS.TCP_PORTS.TCP_PORTS_ADDITIONAL.HAS_ADDITIONAL = 1

            $refinedports = $ports -join (",")
            $root.SCAN.PORTS.TCP_PORTS.TCP_PORTS_ADDITIONAL.ADDITIONAL_PORTS = $refinedports
        }
        else{
            $root.SCAN.PORTS.TCP_PORTS.TCP_PORTS_ADDITIONAL.HAS_ADDITIONAL = 0
        }

        #specific IPs?
        if($searchListID){
            $root.SCAN.VULNERABILITY_DETECTION.CUSTOM_LIST.CUSTOM.ID = $searchListID
            $root.SCAN.VULNERABILITY_DETECTION.CUSTOM_LIST.CUSTOM.TITLE.'#cdata-section' = $searchlistName
        }

        #import it to Qualys
        $data = Invoke-RestMethod -ContentType 'text/xml' -Headers @{"X-Requested-With"="powershell"} -URI "https://$qualysServer/api/2.0/fo/subscription/option_profile/?action=import" -Body $XMLdoc -Method Post -WebSession $cookie
        $data.SIMPLE_RETURN.RESPONSE.Text


    }
    End{}

}