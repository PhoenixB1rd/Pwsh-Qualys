function New-QualysIP{
    <#
        .Synopsis
            Add an IP to a specific Asset Group.

        .DESCRIPTION
            Add an IP to a specific Asset Group. The function will grab all the IPs in the Asset group provided, then check to see if the IP already exists in the group and if it doesn't`
            then it will go ahead and add it to the group specified.

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie

        .PARAMETER ip
            Provide the new IP that you wish to add into Qualys.

        .PARAMETER assetGrpID
            Provide the Asset Group ID that you would like to add the IP to.

        .EXAMPLE
            New-QualysIP -qualysServer $server -cookie $cookie -ip 10.0.0.1 -assetGrpID 1123456

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will check to see if 10.0.0.1 is in the Asset group 1123456, if it isn't, it will add it to the group.

    #>
    [CmdletBinding()]
    Param
    (
        [ValidatePattern("\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")]
        [string]$ip,

        [Parameter(Mandatory)]
        [string]$assetGrpID,

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie
    )

    Begin{}
    Process
    {
        ## Grab the list of IPs
        $data = Get-QualysAssetGrp -qualysServer $qualysServer -cookie $cookie -id $assetGrpID

        # Seperate single IPs from Ranges and CIDRS
        $ips = $data.IPs
        # IP Ranges, these will take more work to extrapolate
        $ipRanges = $data.IPRanges

        ## break up the ip range strings, extract all the ips .. blah blah
        foreach ($range in $ipRanges)
        {
            $splittingTheRange = $range -split "-"
            $resultingips = Get-IPRangeDetails -FirstIP $splittingTheRange[0] -Last $splittingTheRange[1]
            $ips += " " + $resultingips.IPAdddresses
        }
        Write-Verbose "Ips in ips variable $ips"
        ########################### now we have a full list of IPs to check against
        ###  check if IP to be added is is in the list
        if ($ips -notcontains $ip)
        {
            $actionBody = @{
                action = "edit"
                id = $assetGrpID
                add_ips = $ip
            }
            [xml]$response = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -Uri "https://$qualysServer/api/2.0/fo/asset/group/" -Method Post -Body $actionBody -WebSession $cookie
            ## check that it worked
            $response.SIMPLE_RETURN.RESPONSE.TEXT
        }
        else{
             Throw "It appears that the ip already exists in the asset group $data"
            }
    }
    End{}
}