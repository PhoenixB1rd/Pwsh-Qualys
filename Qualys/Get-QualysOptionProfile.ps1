function Get-QualysOptionProfile{
    <#
        .Synopsis
            Not currently useable
        .DESCRIPTION

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie

        .PARAMETER id
            ID of the option profile information that you want to get

        .PARAMETER title
            Please specify the title of the option profile that you want to use, this is case sensitive and must match exactly to an option profile in Qualys. If not used, will return all data.

        .EXAMPLE
            Get-QualysOptionProfile -qualysServer $server -cookie $cookie

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This combination will retrieve information about all Option profile.

        .EXAMPLE
            Get-QualysOptionProfile -qualysServer $server -cookie $cookie -title "test"

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This combination will retrieve information about an Option profile named "test" if it exists. If it doesn't exist or is mispelled the script will return nothing.

    #>
    [CmdletBinding()]
    Param
    (

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie,

        [Parameter()]
        [string]$id,

        [Parameter()]
        [string]$title
    )

    Begin{}
    Process
    {
        if($id -or $title){
            $actionbody = @{}
            if($id){
                $actionbody.Add('option_profile_id',$id)
            }
            if($title){
                $actionbody.Add('option_profile_title',$title)
            }

            $data = Invoke-RestMethod -ContentType 'text/xml' -Headers @{"X-Requested-With"="powershell"} -URI "https://$qualysServer/api/2.0/fo/subscription/option_profile/?action=export" -Body $actionbody -Method Get -WebSession $cookie

            #parse out the important information
            $root = $data.OPTION_PROFILES.OPTION_PROFILE
            $newobj = @{
                ID = $root.Basic_Info.ID
                Name = $root.Basic_Info.Group_Name.'#cdata-section'
                TCP_Ports = $root.Scan.Ports.TCP_PORTS.TCP_PORTS_TYPE
                UDP_Ports = $root.Scan.Ports.UDP_PORTS.UDP_PORTS_TYPE
                Additional_ports = $root.Scan.Ports.TCP_PORTS.TCP_PORTS_ADDITIONAL.ADDITIONAL_PORTS
                Overall_Performance = $profile.Scan.PERFORMANCE.OVERALL_PERFORMANCE
                Detection_Lists = $profile.Scan.VULNERABILITY_DETECTION.CUSTOM_LIST.CUSTOM.ID + "," + $profile.Scan.VULNERABILITY_DETECTION.CUSTOM_LIST.CUSTOM.Title.'#cdata-section'
            }
            $newobj
        }
        else{
            $data = Invoke-RestMethod -ContentType 'text/xml' -Headers @{"X-Requested-With"="powershell"} -URI "https://$qualysServer/api/2.0/fo/subscription/option_profile/?action=export" -Method Get -WebSession $cookie
            $root = $data.OPTION_PROFILES.OPTION_PROFILE
            $newarray = @()
            foreach($profile in $root){
                $lists = $profile.Scan.VULNERABILITY_DETECTION.CUSTOM_LIST.CUSTOM.ID + "," + $profile.Scan.VULNERABILITY_DETECTION.CUSTOM_LIST.CUSTOM.Title.'#cdata-section'
                $object = New-Object PSObject -Property @{
                    Title = $profile.BASIC_INFO.GROUP_NAME.'#cdata-section'
                    ID = $profile.BASIC_INFO.ID
                    TCP_Ports_Type = $profile.Scan.Ports.TCP_PORTS.TCP_PORTS_TYPE
                    UDP_Ports_Type = $profile.Scan.Ports.UDP_PORTS.UDP_PORTS_TYPE
                    Overall_Performance = $profile.Scan.PERFORMANCE.OVERALL_PERFORMANCE
                    Additional_ports = $profile.Scan.Ports.TCP_PORTS.TCP_PORTS_ADDITIONAL.ADDITIONAL_PORTS
                    Detection_Lists = $lists.trim(",")
                    #can add more properties here, but these are the bare minimum. May add more in the future should the need arise or the API output returns more data.
                }
                $newarray += $object
            }
        $newarray
        }


    }
    End{}
}