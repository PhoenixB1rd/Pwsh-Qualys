function Get-QualysReportList{
    <#
        .Synopsis
            Get list of Qualys Reports

        .DESCRIPTION
            Get list of Qualys Reports

        .PARAMETER id
            (Optional) Qualys Report ID, use this to get details on a specific ID

        .PARAMETER qualysServer
                FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie

        .EXAMPLE
            Get-QualysReportList -qualysServer $qualysServer -cookie $cookie -id 1234567

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will return information on only a report with the ID provided

        .EXAMPLE
            Get-QualysReportList -qualysServer $qualysServer -cookie $cookie

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This commmand will return information on all reports within the Qualys subscription.

    #>

    [CmdletBinding()]
    Param
    (
        [string]$id,

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie
    )

    Begin{}
    Process
    {
        $actionBody = @{action = "list"}
        if($id){$actionBody['id'] = $id}
        [xml]$returnedXML = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -Uri "https://$qualysServer/api/2.0/fo/report/" -Method Get -Body $actionBody -WebSession $cookie
        $data = $returnedXML.REPORT_LIST_OUTPUT.RESPONSE.REPORT_LIST.REPORT
        $data
    }
    End{}
}