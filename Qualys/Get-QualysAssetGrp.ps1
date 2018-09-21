function Get-QualysAssetGrp{
    <#
        .Synopsis
            Get a list of AssetGroup IDs or the ID for a specific AssetGroup

        .DESCRIPTION
            Get a list of AssetGroup IDs or the ID for a specific AssetGroup

        .PARAMETER id
            Asset Group ID, use this to get a single Asset Group

        .PARAMETER title
            Provide the title of the asset group you need the information for. Its is Case sensitive as the asset group title needs to match EXACTLY.

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie

        .PARAMETER all
            Use this switch to grab all asset groups from the qualys account.

        .EXAMPLE
            Get-QualysAssetGrp -qualysServer $server -cookie $cookie -title "Testing"

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            The result of the script will return information on the the Asset Group "Testing" if it exists within your Qualys Subscription. Otherwise will return a not found error.

        .EXAMPLE
            Get-QualysAssetGrp -qualysServer $server -cookie $cookie -id 123456

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            The result of the script will return information on the the Asset Group with the ID 123456 if it exists within your Qualys Subscription.

        .EXAMPLE
            Get-QualysAssetGrp -qualysServer $server -cookie $cookie -all

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            Using the "all" switch will grab all asset groups within the qualys account that the credentials used has access to.
    #>

    [CmdletBinding()]
    Param
    (
        [Parameter(ParameterSetName = "id")]
        [string]$id,

        [Parameter(ParameterSetName = "title")]
        [string]$title,

        [Parameter(ParameterSetName = "All")]
        [switch]$all,

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie
    )

    Begin{}
    Process
    {
        $actionBody = @{
            action = "list"
        }
        if($id){
            $actionBody.ids = "$id"
        }
        if($title){
            $actionBody.Add("title",$title)
        }
        [xml]$returnedXML = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -Uri "https://$qualysServer/api/2.0/fo/asset/group" -Method Get -Body $actionBody -WebSession $cookie
        [System.Xml.XmlElement]$root = $returnedXML.get_DocumentElement()
        $data = $root.RESPONSE.ASSET_GROUP_LIST.ASSET_GROUP
        if($data.length -ne 0 ){
            #Creating an empty hash table to gather all the data
            $results = @()
            foreach ($assetGroup in $data){
            #seperating the data to expand all the groups to retrieval all the data and then place it in a PSObject to create useable data
            $obj = New-Object PSObject -Property @{
                ID = $assetGroup.ID
                Title = $assetGroup.Title.'#cdata-section'
                Ips = ($assetGroup.IP_SET.IP -join ',') # the join is to create the commas in between IPs for spreadsheets.
                IpRanges = ($assetGroup.IP_SET.IP_RANGE -join ',')
                NetworkId = ($assetGroup.Network_IDS -join ',')
                }
                $results += $obj
            }
            return [pscustomobject]$results
        }
        else{
            Write-Error -Message "No results were returned, if you using the Title of the AssetGroup ensure that it is spelled EXACLTY and that the case is correct. Else, there was no ID found, try again."
        }

    }
    End{}
}