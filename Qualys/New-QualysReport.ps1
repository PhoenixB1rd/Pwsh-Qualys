function New-QualysReport{
    <#
        .Synopsis
           Will create a report based on the fields and specifications that is specified.

        .DESCRIPTION
            Will create a report based on the fields and specifications that is specified.

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie

        .PARAMETER title
            Name that the report will have. Title is needed.

        .PARAMETER templateID
            The ID of the template that the report will be create off of. Template ID can be generated with New-QualysReportTemplate

        .PARAMETER outputFormat
            The resulting document type that the report will generate. Possible values are: PDF, CSV or HTML.

        .PARAMETER reportType
            Select the type of Report you wish to generate. Note that some report types do not support CSV output. Possible values are: Scan, Remediation, Compliance, PCI.

        .PARAMETER ips
            Provide a list of IPs if different from the ones set in the report template.

        .PARAMETER assetgroup
            Provide a list of Asset Groups that you wish to be included in the report that are not in the original report template.

        .PARAMETER scanRefID
            Provide the scan that you would like the report from if the report type is "scan".

        .example
            New-QualysReport -templateID 123456 -title QID43557 -qualysServer $server -cookie $cookie -assetgroup "All" -outputFormat csv -reportType Scan

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will start a new report that can be downloaded when it is finished. The output is the ID of that report.

        .EXAMPLE
             New-QualysReport -templateID 123456 -title QID43557 -qualysServer $server -cookie $cookie -assetgroup "All" -outputFormat csv -reportType Scan -scanRefID "scan/1532909079.97658"

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will start a new report from the scan results of scan/1532909079.97658. At the report wo;; be downloaded when it is finished. The output is the ID of that report.

    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$templateID,

        [Parameter(Mandatory)]
        [string]$title,

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie,

        [Parameter(Mandatory)]
        [ValidateSet('pdf','csv','html')]
        [string]$outputFormat = "csv",

        [Parameter(Mandatory)]
        [ValidateSet('Scan','Remediation','Compliance','PCI')]
        [string]$reportType = "Scan",

        [Parameter()]
        [string[]]$ips,

        [Parameter()]
        [string[]]$assetgroup,

        [Parameter]
        [string]$scanRefID
    )

    Begin{
        #check what kind of report template is being used as certain templates don't have a csv option for output
        if(($outputFormat -eq "csv") -and ($reportType -eq "PCI" -or $reportType -eq "Compliance")){
           Throw "Report types PCI and Compliance do not have an output that accepts CSV format. Please select a different format."
        }
        $actionBody= @{
            action ="launch"
            template_id = $templateID
            output_format = $outputFormat
            report_type = $reportType
            report_title = $title
        }
        if($ip){
            $actionBody.add("ips",$ips)
        }
        if($scanRefID){
            $actionBody.add("report_refs",$scanRefID)
        }
    }
    Process
    {
        #lookup the Asset group that was specified and throw an error if its not found.
        if($assetgroup){
            $ids = @()
            foreach($group in $assetgroup){
                $assetGrp = Get-QualysAssetGrp -title $group -qualysServer $qualysServer -cookie $cookie
                $id = $assetGrp.ID
                $ids += $id
            }
            $list = $ids -join ","
            $actionBody.Add("asset_group_ids",$list)
        }
        $results = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -Uri "https://$qualysServer/api/2.0/fo/report/" -Method POST -Body $actionBody -WebSession $cookie
        $root = $results.SIMPLE_RETURN.RESPONSE
        $ID = $results.SIMPLE_RETURN.RESPONSE.ITEM_LIST.Innertext.Split("ID").Trim()
        $newobj = New-Object PSObject -Property @{
            Info = $root.Text
            ID = $ID[1]
        }
        $newobj
    }
    End{}
}