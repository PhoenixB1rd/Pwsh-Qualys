function New-QualysReportTemplate{
    <#
        .Synopsis
            Used to create a new report template in Qualys that can then be plugged into other Qualys functions like New-QualysScan

        .DESCRIPTION
            Used to create a new report template in Qualys that can then be plugged into other Qualys functions like New-QualysScan

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER assetCookie
            Use Connect-Qualys to get session cookie that can be used with their legacy API by setting the -AssetTagging when creating the cookie.

        .PARAMETER templatedoc
            Import the XML template doc for the report template. One is provided in the module and is labeled ReportTemplate.xml

        .PARAMETER title
            Provide a name for the report template. Import will not work if there is no name.

        .PARAMETER searchlistID
            Please Supply the search list ID to be associated with the option profile. This is not required, but if you choose this option you will also need to provide the dynamic search list name.

        .EXAMPLE
            New-QualysReportTemplate -qualysServer $server -cookie $cookie -templateDoc ./Documents/Github/Qualys-Powershell/Qualys/ReportTemplateTemplate.xml -title $title -searchlistID 12345

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will create a new report template in Qualys, will return information about the newly created template.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$assetCookie,

        [Parameter(Mandatory)]
        [string]$templateDoc,

        [Parameter(Mandatory)]
        [string]$title,

        [Parameter(Mandatory)]
        [string]$searchlistID,

        [Parameter()]
        [switch]$global
    )

    Begin{}
    Process
    {
        #Pick-up the template so it can be modified

        [xml]$XMLdoc =(Get-Content $templatedoc)
        $root = $XMLDoc.REPORTTEMPLATE.SCANTEMPLATE
        #Set the Global Variable

        if($global){
            $global2 = '1'
        }
        else{
            $global2 = '0'
        }

        #edit the title of the template

        $root.TITLE.Info.'#cdata-section' = $title

        #edit the search list information

        $root.Filter.Info[1].'#cdata-section' = $searchlistID

        #edit the global properties

        $root.USERACCESS.INFO[1].'#cdata-section' = $global2

        #send the finished template to Qualys
        $data = Invoke-RestMethod -ContentType 'text/xml' -Headers @{"X-Requested-With"="powershell"} -URI "https://$qualysServer/api/2.0/fo/report/template/scan/?action=create&report_format=xml" `
        -Method POST -Body $XMLdoc -WebSession $assetCookie
        if($data.SIMPLE_RETURN.RESPONSE.Text -eq "Scan Report Template(s) Successfully Created."){
            $templates = Get-QualysReportTemplate -AssetCookie $cookie -qualysServer $qualysServer
            $templates | where {$_.Title -eq $title}
        }
        else {
            throw "The creation of the Report did not work."
        }
    }
    End{}
}