function Get-QualysScannerList{
    <#
        .Synopsis
            Return a list of Scan Appliances with only their IDs, Name, IP address and Netmask returned returned

        .DESCRIPTION
            Return a list of Scan Appliances with only their IDs, Name, IP address and Netmask returned returned

        .PARAMETER qualysServer
            Which Qualys Server to send the API request too

        .PARAMETER cookie
            Provide the cookie to connect to an authenticated Qualys session. Usually the output of Connect-Qualys

        .EXAMPLE
            $data = Get-QualysScannerList -qualysServer $server -cookie $cookie

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will return the ID, IP, name, if its active or not, the asset groups assigned to them, the asset tags they are assigned to and the netmask of the scanners within Qualys. Its `
            recommended to save the output to a variable. This provides a way to drill down into the Asset Group list and Asset Tag list that would be otherwise unavailable.
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
    Process{
        $actionBody= @{
            action ="list"
            output_mode = "full"
        }
        [xml]$xmlResponse = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -URI "https://$qualysServer/api/2.0/fo/appliance/" -Method Get -WebSession $cookie -Body $actionBody
        [System.Xml.XmlElement]$root = $xmlResponse.get_DocumentElement()
        $data = $root.RESPONSE.APPLIANCE_LIST.APPLIANCE
                #Creating an empty hash table to gather all the data
       $results = @()
       foreach ($scanner in $data){

            #grabbing only the LAN interface
            $Interfaces = $scanner.INTERFACE_SETTINGS
            foreach($Interface in $Interfaces){
                if($Interface.INTERFACE -eq "lan"){
                    $LAN = $Interface.IP_ADDRESS
                    $Mask = $interface.NETMASK
                }
            }
            #seperating the data to expand all the groups to retrieval all the data that is important and then place it in a PSObject to create useable data
            #need to add asset group, asset tags and version
            $obj = New-Object PSObject -Property @{
                ID = $scanner.ID
                Name = $scanner.Name
                Ip = $LAN
                NetMask = $Mask
                Connection = $scanner.SS_CONNECTION
                Asset_Tag_List = $scanner.ASSET_TAGS_LIST.ASSET_TAG.Name.'#cdata-section'
                Asset_Group_List = $scanner.Asset_Group_List.ASSET_GROUP.Name.'#cdata-section'
                }
                $results += $obj
        }
        return [pscustomobject]$results

    }

    End{}
}
