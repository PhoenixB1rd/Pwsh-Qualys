function Get-QualysAssetReport{
    <#
        .Synopsis
            Will grab an asset report. Supporting functionality for AWS EC2 instances, tags and asset groups. More functionality will be added.
        .DESCRIPTION
            Will grab an asset report. Supporting functionality for AWS EC2 instances, tags and asset groups. More functionality will be added.
        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie

        .PARAMETER ec2
            Use the switch to specify if you only want to show Ec2 instance. IF used, will need to provide tags that are associated with EC2 or AWS

        .PARAMETER tags
            Specify the Tag set that you want to search on, must be used in conjunction with the EC2 switch

        .PARAMETER status
            Specify what state the EC2 instance is in, if using the EC2 flag.

        .PARAMETER assetID
            Currently not used in the script. Intended functionality for the future is to look up a specific assetID in AWS.

        .PARAMETER assetGroupName
            If you want to look up assets by an asset group, specify the asset group as it would match exactly the group in Qualys. Is case sensitive.

        .PARAMETER assetGroupID
            If you want to look up assets by an asset group, specify the asset group ID.

        .EXAMPLE
            $report = Get-QualysAssetReport -qualysServer $server -cookie $cookie -lastVulnScanDays 90 -assetGroupName "All"

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            Store CSV data in the $report variable from the function. The function will grab all assets that have been scanned in the last 90 days that are in the Asset Group "All".

        .EXAMPLE
            $report = Get-QualysAssetReport -qualysServer $server -cookie $cookie -ec2 -tag 11223344 -status STOPPED

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            Store the CSV data in the report variable to be exported with the out-file command. The command will retrieve information on the assets within the tag 11223344 `
             with the Ec2 instance state of "STOPPED".

        .EXAMPLE
            $report = Get-QualysAssetReport -qualysServer $server -cookie $cookie -tag 12345667

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            Store the CSV data in the $report variable to be exported later for ease of use. This command will retrieve all items in the tag 12345667. Tag ID's can `
            be found using the Get-QualysTag function.
    #>
    [CmdletBinding(DefaultParameterSetName='non-AWS')]
    Param
    (
        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie,

        [Parameter(ParameterSetName='AWS',Mandatory=$true)]
        [switch]$ec2,

        [Parameter(ParameterSetName='AWS',Mandatory=$false)]
        [Parameter(ParameterSetName='non-AWS',Mandatory=$false)]
        [Parameter(ParameterSetName='tag')]
        [string[]]$tag,

        [Parameter(ParameterSetName='tag',Mandatory=$true)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$assetCookie,

        [Parameter(ParameterSetName='AWS')]
        [ValidateSet("RUNNING","TERMINATED","PENDING",
        "STOPPING","SHUTTING_DOWN","STOPPED")]
        [string]$status = "RUNNING",

        [Parameter(ParameterSetName='non-AWS')]
        [string[]]$ip,

        [Parameter(ParameterSetName='non-AWS')]
        [string[]]$assetGroupName,

        [Parameter(ParameterSetName='non-AWS')]
        [string[]]$assetGroupID,

        # parameter to search for assets that have been scanned in the last x days
        [Parameter(ParameterSetName='non-AWS')]
        [Parameter(ParameterSetName='scandate')]
        [Int64]$lastVulnScanDays,

        # parameter used to specify within or not within the scope of the days of last scanned specified above
        [Parameter(ParameterSetName='scandate',Mandatory=$true)]
        [Parameter(ParameterSetName='non-AWS')]
        [ValidateSet("within","not within")]
        [string]$scanModifier = "within"

    )

    Begin{}
    Process
    {

        $actionBody = @{
            action = 'search'
            output_format = 'csv'
        }

        if($ec2){
            $actionBody.Add("tracking_method",'EC2')
            $actionBody.Add("use_tags",1)

            #ensuring that the tags are comma seperated
            $refinedTags = $tag -join (",")
            $actionBody.Add("tag_set_include",$refinedTags)

            $actionBody.Add("ec2_instance_status",$status)
        }
        else{
            if($ip){
                $actionBody.Add("ips",$ips)
            }

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
            if($assetGroupIDList.length -ne 0){
                $actionBody.Add("asset_group_ids",$assetGroupIDList.trim(","))
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
            if($lastVulnScanDate){
                $actionBody.add("last_vm_scan_days",$lastVulnScanDays)
                $actionBody.add("last_vm_scan_modifier",$scanModifier)
            }

        }
        Write-Verbose $actionbody
        $data = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -Uri "https://$qualysServer/api/2.0/fo/report/asset/" -Method Get -Body $actionBody -WebSession $cookie

        if($data.SIMPLE_RETURN.RESPONSE){
            $data.SIMPLE_RETURN.RESPONSE
        }
        else{
            $newvariable = $data -split '"IP"'
            $lastvariable = '"IP"' + $newvariable[1]
            $lastvariable | out-file temp.csv
            $psObject = Import-csv temp.csv
            rm temp.csv
            $psObject
        }
    }
    End{}
}