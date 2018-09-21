function Get-QualysReport{
    <#
        .Synopsis
            Download Qualys Report

        .DESCRIPTION
            Download Qualys Report

        .PARAMETER id
            Report ID, use Get-QualysReportList to find the ID

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get a session cookie

        .PARAMETER outFilePath
            Provide the path where the file will be placed after download.

        .EXAMPLE
            Get-QualysReport -qualysServer $server -cookie $cookie -id 16552365 -outFilePath ./

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will download the report with ID 16552365 to the current directory. The ID for the report that you want can be found using Get-QualysReportList.

    #>

        [CmdletBinding()]
        Param
        (
            [Parameter(Mandatory)]
            [string]$id,

            [Parameter(Mandatory)]
            [string]$outFilePath,

            [Parameter(Mandatory)]
            [string]$qualysServer,

            [Parameter(Mandatory)]
            [Microsoft.PowerShell.Commands.WebRequestSession]$cookie
        )

        Begin{}
        Process
        {
            ### get the format type
            $format = (Get-QualysReportList -qualysServer $qualysServer -cookie $cookie -id $id).OUTPUT_FORMAT
            $outfile = "$outFilePath\qualysReport$ID.$format"

            $data = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -Uri "https://$qualysServer/api/2.0/fo/report/" -Method get -Body @{action = "fetch";id = "$id"} -WebSession $cookie -OutFile $outfile
            $data
        }
        End{}
    }