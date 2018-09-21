function Export-QualysOptionProfile {
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
            Optional to export one full ID worth of a profile

        .PARAMETER path
            Provide an xml file name to export one profile id to.

        .PARAMETER less
            To use in conjunction with id, will get only the ID and name instead of the entire profile.

        .EXAMPLE
            Export-QualysOptionProfile -qualysServer $server -cookie $cookie

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will export all option profiles.

        .EXAMPLE
            Export-QualysOptionProfile -qualysServer $server -cookie $cookie -id 9876543 -path ./testing.xml

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This function will retrieve information on the option profile with ID 9876543 and place it into a file titled ./testing.xml

    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie,

        [Parameter(ParameterSetName='ID')]
        [string]$id,

        [Parameter(ParameterSetName='ID')]
        [string]$path,

        [Parameter(ParameterSetName='ID')]
        [switch]$less
    )

    Begin{}
    Process
    {
        $actionBody = @{
            action = "export"
        }

        if($id){
            $actionBody.Add("option_profile_id","$id")
        }

        [xml]$xmlResponse = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -URI "https://$qualysServer/api/2.0/fo/subscription/option_profile" -Method Get -WebSession $cookie -Body $actionBody
        $data = $xmlResponse.option_profileS.OPTION_PROFILE

        if($path){
            $xmlResponse.InnerXml >> $path
            return $true
        }
        elseif($id){
            return [pscustomobject]$data
        }
        else{
            $results = @()
            foreach ($profile in $data){

                #seperating the data to expand all the groups to retrieval all the data that is important and then place it in a PSObject to create useable data
                $obj = [pscustomobject]@{
                    ID = $profile.Basic_Info.ID
                    Name = $profile.Basic_Info.Group_Name.'#cdata-section'
                        #other information can be added here as needed.
                    }
                    $results += $obj
            }
            return [pscustomobject]$results
        }
    }
    End{}
}