function New-QualysScan{
    <#
        .Synopsis
            Not currently useable - need to validate that the script works.
        .DESCRIPTION

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie.

        .PARAMETER scantitle
            Give a title for the scan.

        .PARAMETER optionprofileID
            Will need to run New-QualysOption Profile to retrieve the option profile ID. There is currently no functionality to list option profiles, to be made.

        .PARAMETER priority
            On a number scale of 0-9 what priority do you want set for. The lower the number the higher the priority. 0 meaning no priority, 1 being an emergency all the way to 9 being a Low `
            priority.

        .PARAMETER ip
            Provide an ip or list of ips that you want scanned. One of the parameters IP, AssetGroupID, AssetGroupName or NetworkID are required for the script to run.

        .PARAMETER assetGroupID
            Provide the Asset Group IDs that you want to include in the scan. The asset IDs can be retrieved from Get-QualysAssetGroup.

        .PARAMETER assetGroupName
            Provide the names of the Asset Groups that you want to include. These names have to match exactly or they will be not be scanned.

        .PARAMETER excludeIP
            If there are any IPs that you want to exclude from the scan.

        .PARAMETER tag
            Use this switch if you want to use any form of tags in the scan. Using this switch unlocks a whole set of other parameters.

        .PARAMETER tagname
            Please list the names of the tags that you want to use. Tag names need to match the tag exactly.

        .PARAMETER tagExclude
            Please list the names of the tags that you DON'T want to use. Tag names need to match exactly.

        .PARAMETER scannerName
            Provide the name of the scanner you would like to use with this scan. The name of the scanner can be found using Get-QualysScannerList

        .EXAMPLE
            New-QualysScan -qualysServer $server -cookie $cookie -scantitle "Testing" -optionProfileID 123456 -priority 0 -AssetGroupName "All" -Scanner PROD1

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will start a new scan with the name Testing, with no priority, using the asset Group all with the scanner name PROD1.

    #>
    [CmdletBinding()]
    Param
    (

        [Parameter(Mandatory = $true)]
        [string]$qualysServer,

        [Parameter(Mandatory = $true)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie,

        [Parameter(Mandatory = $true)]
        [String]$scantitle,

        [Parameter(Mandatory = $true)]
        [string]$optionprofileID,

        #Indicate the priority in which the scan should be. A lower number means that the scan will have higher priority
        [Parameter()]
        [ValidatePattern('^[0-9]$')]
        [string]$priority,

        #Options for asset groups or ips
        [Parameter()]
        [string]$ip,

        [Parameter()]
        [string[]]$assetGroupID,

        [Parameter()]
        [string[]]$assetGroupName,

        [Parameter()]
        [string[]]$excludeIP,

        [Parameter(ParameterSetName = 'Tag',Mandatory = $true)]
        [switch]$tag,

        #need a list of variables just for the tag parameter
        [Parameter(ParameterSetName = 'Tag',Mandatory = $true)]
        [string[]]$tagsName,

        [Parameter(ParameterSetName = 'Tag')]
        [string[]]$tagsExclude,

        [Parameter(ParameterSetName = 'Tag',Mandatory = $true)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$assetCookie,

        [Parameter(Mandatory = $True)]
        [string]$scannerName
      )

    Begin{}
    Process
    {
        #Verifiy that ips or an asset group parameter was specified
        if($assetGroupID -and $ip -and $assetGroupName -and $networkID -eq $false){
            throw "Please run command with one or all of these parameters: IP, AssetGroupID, AssetGroupName or NetworkID."
        }

        #Verify that the scanner name provided exists
        $RealScannerNames = Get-QualysScannerList -qualysServer $qualysServer -cookie $cookie | Where {$_.Connection -eq "Active"} | Select -ExpandProperty name
        if($RealScannerNames -notcontains $scannerName){
            Throw "Scanner Name did not match a Scanner that is active in the subscription or did not match exactly. Please use Get-QualysScannerList to find the right scanner name."
        }

        $actionbody = @{
            action = 'launch'
            scan_title = $scantitle
            option_id = $optionprofileID
            priority = $priority
            iscanner_name = $scannerName
        }

        #validate that the asset groups exist
        if($assetGroupID -or $assetGroupName){
            $groupIds = ""
            foreach($id in $assetGroupID){
                $response = Get-QualysAssetGroup -qualysServer -cookie $cookie -id $id
                if($response.length -eq 0){
                    Write-Error -Message "No Asset Group was found with the id $id"
                }
                else{
                    $groupIds += $id + ","
                }
            }
            foreach($name in $assetGroupName){
                $response = Get-QualysAssetGroup -qualysServer -cookie $cookie -title $name
                if($response.length -eq 0){
                    Write-Error -Message "No Asset Group was found with the name : $name"
                }
                else{
                    $groupIds += $id + ","
                }
            }
            $actionbody.add('asset_group_ids',$groupIds)
        }

        #grab the tag information if the tag switch was provided.
        if($tag){
            $actionbody.add('target_from','tags')
            if($tagsname){
                #validating the tags
                $taglist = ""
                foreach($obj in $tagsName){
                    $response = Get-QualysTag -qualysServer $qualysServer -assetCookie $assetCookie -operator EQUALS -searchField name -searchTerm $obj
                    if($response.length -eq 0){
                        Write-Error -Message "Tag with name: $tag was not found"
                    }
                    else{
                        $taglist += $response.id + ","
                    }
                }
                $actionbody.add('tag_set_include',$taglist.trim(","))
            }
            if($tagsExclude){
                #validating the tags
                $taglist2 = ""
                foreach($obj2 in $tagsExclude){
                    $response = Get-QualysTag -qualysServer $qualysServer -assetCookie $assetCookie -operator EQUALS -searchField name -searchTerm $obj2
                    if($response.length -eq 0){
                        Write-Error -Message "Tag with name: $tag was not found"
                    }
                    else{
                        $taglist2 += $response.id+ ","
                    }
                }
                $actionbody.add('tag_set_include',$taglist.trim(","))
            }
        }

        if($ip){
            $actionbody.add('ip',$ip)
        }
        if($excludeIP){
            $actionbody.add('exclude_ip_per_scan',$excludeIP)
        }
        #execute after putting all the variables into action
        $data = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -Uri "https://$qualysServer/api/2.0/fo/scan/" -Method POST -Body $actionbody -WebSession $cookie

        #check if it was successful
        if($data.SIMPLE_RETURN.RESPONSE.TEXT -eq "New vm scan launched"){
            [xml]$xml = $data.SIMPLE_RETURN.RESPONSE.ITEM_LIST.OuterXml
            $object = New-Object PSCustomObject @{
                response = $data.SIMPLE_RETURN.RESPONSE.TEXT
                scanRefID = $xml.ITEM_LIST.InnerText
            }
            $object
        }
        else{
            $data.SIMPLE_RETURN.RESPONSE
        }

    }
    End{}
}