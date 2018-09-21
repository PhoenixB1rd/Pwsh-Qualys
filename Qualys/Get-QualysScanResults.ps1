function Get-QualysScanResults{
    <#
        .Synopsis
            Get results of Qualys Scan

        .DESCRIPTION
            Get reults of Qualys Scan

        .PARAMETER scanRef
            Qualys Scan Reference, use Get-QualysScanList to find the reference

        .PARAMETER additionalOptions
            See documentation for full list of additional options and pass in as hashtable

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie

        .EXAMPLE
            Get-QualysScanResults -qualysServer $server -cookie $cookie -scanRef scan/123456789.12345

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This command will return the results from the scan scan/123456789.12345

        .NOTES
            If you want more information on what additional options you can provide, visit the API user documentation at https://www.qualys.com/docs/qualys-api-v2-user-guide.pdf on pg.34.

    #>

    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$scanRef,

        [Parameter()]
        [System.Collections.Hashtable]$additionalOptions,

        [Parameter()]
        [switch]$brief,

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie
    )

    Begin{}
    Process
    {
        $actionBody = @{
            action = "fetch"
            scan_ref = $scanRef
            output_format='csv'
        }
        if($additionalOptions){
            $actionBody += $additionalOptions
        }
        Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -Uri "https://$qualysServer/api/2.0/fo/scan/" -Method Get -Body $actionBody -WebSession $cookie
    }
    End{}
}