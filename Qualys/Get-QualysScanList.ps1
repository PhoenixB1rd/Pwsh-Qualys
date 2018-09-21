function Get-QualysScanList{
    <#
        .Synopsis
            Get list of Qualys Scans

        .DESCRIPTION
            Get list of Qualys Scans

        .PARAMETER scanRef
            (Optional) Qualys Scan Reference, use this to get details on a specific Scan

        .PARAMETER additionalOptions
            See documentation for full list of additional options and pass in as hashtable

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie

        .EXAMPLE
            Get-QualysScanList -qualysServer $server -cookie $cookie

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will return a list of all Scans, including their status, processing priority, targets and other data.

        .EXAMPLE
            Get-QualysScanList -qualysServer $server -cookie $cookie -scanRef scan/123456789.12345

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will return information on the scan with reference ID of scan/123456789.12345.
    #>

    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [string]$scanRef,

        [System.Collections.Hashtable]$additionalOptions,

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
        if($scanRef){
            $actionBody['scan_ref'] = $scanRef
        }
        if($additionalOptions){
            $actionBody += $additionalOptions
        }
        $finalresults = @()
        [xml]$returnedXML = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -Uri "https://$qualysServer/api/2.0/fo/scan/" -Method Get -Body $actionBody -WebSession $cookie
        $data = $returnedXML.SCAN_LIST_OUTPUT.RESPONSE.SCAN_LIST.SCAN
        foreach($object in $data){
            $finalresults += New-Object PSObject -Property @{
                REF = $object.REF
                Type = $object.TYPE
                Title = $object.title.'#cdata-section'
                User_Login = $object.USER_LOGIN
                Next_Launch_Date = $object.LAUNCH_DATETIME
                Processing_Priority = $object.PROCESSING_PRIORITY
                Processed = $object.Processed
                Status = $object.STATUS.State
                Targets = $object.TARGET.'#cdata-section'
            }
        }
        [pscustomobject]$finalresults
    }
    End{}
}