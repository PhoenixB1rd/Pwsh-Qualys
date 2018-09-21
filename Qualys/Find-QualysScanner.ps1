function Find-QualysScanner {
    <#
        .Synopsis
            Find the scanner that is in the same network as the IP given, can also provide a correlation with Datacenter CIDR notated network IDs.

        .DESCRIPTION
            Find the scanner that is in the same network as the IP given

        .PARAMETER ip
            Provide an ip or a list of IPs to sort to an appropriate scanner appliance

        .PARAMETER qualysServer
            Which Qualys Server to send the API request too

        .PARAMETER cookie
            Provide the cookie to connect to an authenticated Qualys session. Usually the output of Connect-Qualys.

        .EXAMPLE
            Find-QualysScanner -qualysServer $server -cookie $cookie -ip 10.0.0.1

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            Will match a Qualys scanner within your subscription to the IP address specified using subnet math to determine if the scanner is in the same subnet at the IP.
    #>

    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [string[]]$ip,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie

    )

    Begin{}
    Process{
        #grabbing all scanner appliance to later be tested against
        $scanners = Get-QualysScannerList -qualysServer $qualysServer -cookie $cookie

        ##creating an emtpy variable to store the results later
        $results = @{}
        foreach($unknownip in $ip){

            #grabbing the first and second sections of the IP to provide further fine-tuning
            $firstpart = $unknownip.split(".")[0]
            $secondpart = $unknownip.split(".")[1]

            #creating an empty array for all the matching scanners
            $matchlist = @()
            foreach($appliance in $scanners){
                #matching the ip to the first part of the scanner appliances to reduce the script math load that is coming up
                if($appliance.Ip.split(".")[0] -eq $firstpart){
                    #matching further to again reduce math and hopefully save some time and CPU
                   if($appliance.Ip.split(".")[1] -eq $secondpart){
                        #changing strings to System.Net.IPAddress to use the built in properties

                        [IPAddress]$subnet = $appliance.NetMask
                        [IPAddress]$scannerIP = $appliance.IP
                        [IPAddress]$Unknown = $unknownip

                        #beginning of the math to compare if the ip belongs within the same subnet as the scanner
                        if(($scannerIP.address -band $subnet.address) -eq ($Unknown.address -band $subnet.address)){
                            $matchlist += $appliance.Name
                        }
                    }
                }
            }

            $results.add($unknownip,$matchlist)
        }
        return $results
    }

    End{}

}