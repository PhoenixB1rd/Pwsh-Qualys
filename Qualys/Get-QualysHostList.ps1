function Get-QualysHostList{
       <#
        .Synopsis
            Not currently useable
        .DESCRIPTION
            Intended to be an alternative API to Asset Report. This function will search for a hosts using the parameters provided. Is the prefferred method to querying`
            for a list of hosts.
        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie

        .PARAMETER ec2
            Use the switch to specify if you  want to show Ec2 instance.

        .PARAMETER tags
            Specify the Tag set that you want to search on.

        .PARAMETER assetGroupName
            If you want to look up assets by an asset group, specify the asset group as it would match exactly the group in Qualys. Is case sensitive.

        .PARAMETER assetGroupID
            If you want to look up assets by an asset group, specify the asset group ID.

        .PARAMETER lastVMScanDate
            Provide the date in YYYY-MM-DD format to return results that were scanned since the data specified.

        .EXAMPLE
            $report = Get-QualysHostList -qualysServer $server -cookie $cookie -lastVMScanDate 2018-06-31 -assetGroupName "All"

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            Store data in the $report variable from the function. The function will grab all assets that have been scanned since 2018-06-31 that are in the Asset Group "All".

        .EXAMPLE
            $report = Get-QualysHostList -qualysServer $server -cookie $cookie -ec2

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            Store the data in the report variable to be exported with the out-file or export-csv command. The command will retrieve information on the all assets including ec2 metadata.

        .EXAMPLE
            $report = Get-QualysHostList -qualysServer $server -cookie $cookie -tag 12345667

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            Store the data in the $report variable to be exported later for ease of use. This command will retrieve all items in the tag 12345667. Tag ID's can `
            be found using the Get-QualysTag function.
    #>
    [CmdletBinding(DefaultParameterSetName='non-AWS')]
    Param
    (
        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie,

        [Parameter(Mandatory=$false)]
        [switch]$ec2,

        [Parameter(ParameterSetName='tag')]
        [string[]]$tag,

        [Parameter(ParameterSetName='tag',Mandatory=$true)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$assetCookie,

        [Parameter()]
        [string[]]$assetGroupName,

        [Parameter()]
        [string[]]$assetGroupID,

        # parameter to search for assets that have been scanned in the last x days
        [Parameter()]
        [string]$lastVMScanDate

    )

    Begin{}
    Process
    {

        $actionBody = @{
            action = 'list'
            truncation_limit = 1000000
            details="All"
        }

        if($ec2){
            $actionBody.Add("host_metadata",'EC2')
            $actionBody.Add("host_metadata_fields","accountID,region,instanceID,kernelId")
        }
        else{

            $assetGroupIDList = $null
            if($assetGroupName){
                #grabbing the assetID and verifying that the asset exists
                foreach($group in $assetGroupName){
                    $groupinfo = Get-QualysAssetGrp -qualysServer $qualysServer -title $group -cookie $cookie
                    $assetGroupIDList += $groupinfo.ID + ","
                }
            }
            if($assetGroupID){
                #verifying that the asset group exists
                foreach($group in $assetGroupID){
                    $groupinfo = Get-QualysAssetGrp -qualysServer $qualysServer -cookie $cookie -id $group
                    $assetGroupIDList += $groupinfo.ID + ","
                }
            }
            Write-Verbose "Asset Group list contains $($assetGroupIDList) which hopefully contains the $($AssetGroupName) and $($assetGroupID)"
            if($assetGroupIDList.length -ne 0){
                $actionBody.Add("ag_ids",$assetGroupIDList.trim(","))
            }
            if($tag){
                #verify that the tags exist
                $verifiedtags = ""
                foreach($item in $tag){
                    $taginfo = Get-QualysTag -qualysServer $qualysServer -cookie $assetCookie -searchTerm $item -operator EQUALS
                    if($taginfo.length -ne 0){
                        $verifiedtags += $taginfo.id + ","
                    }
                    else{
                        Write-Error -Message "Tag with name $item was not found, check the spelling and the case. It needs to match EXACTLY."
                    }
                }
                if($verifiedtags.length -ne 0){
                    $actionBody.Add("use_tags",1)
                    $actionBody.Add("tag_set_include",$verifiedtags.trim(","))
                }
            }
            if($lastVMScanDate){

                $actionBody.add("vm_scan_since",$lastVMScanDate)
            }

        }
        #write verbose for the action table for troubleshooting
        foreach($k in $actionbody.Keys){
            Write-Verbose "$k $($actionbody[$k])"
        }

        $data = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -Uri "https://$qualysServer/api/2.0/fo/asset/host/" -Method Get -Body $actionBody -WebSession $cookie
        $list = $data.HOST_LIST_OUTPUT.RESPONSE.HOST_LIST.HOST
        if($list.length -ne 0){
            $newlist = @()
            $z=0
            foreach($obj in $list){
                $newlist += New-Object PSObject -Property @{
                    ID = $obj.ID
                    IP = $obj.IP
                    Tracking_Method = $obj.TRACKING_METHOD
                    Network_Id = $obj.NETWORK_ID
                    DNS = $obj.DNS.'#cdata-section'
                    OS =$obj.OS.'#cdata-section'
                    Last_VM_Scan_date = $obj.LAST_VULN_SCAN_DATETIME
                    Last_VM_Scan_Duration = $obj.LAST_VM_SCANNED_DURATION
                }
                $z++
                Write-Progress -Activity "Converting Results" -Status "Converted $z of $($list.count)" -PercentComplete (($z / $list.count) * 100 )
            }
            $newlist
        }
        else{
            $data
        }
    }
    End{}
}