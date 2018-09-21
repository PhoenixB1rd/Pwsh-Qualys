function Export-QualysReportTemplate{
    <#
        .Synopsis
            Retrieve a list of report templates and their respective ID's to be used in later functions.

        .DESCRIPTION
            Retrieve a list of report templates and their respective ID's to be used in later functions.

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie

        .PARAMETER templateID
            If the template ID is known, it can be verified that it exists using this method.

        .PARAMETER full
            Use this switch to download the entire xml template. Will return the template in xml form, its recommended that it is saved to a file.

        .EXAMPLE
            Export-QualysReportTemplate -qualysServer $server -cookie $cookie

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will return a list of all report templates. The information returned will be: Title, ID and SearchlistID used in that report template.

        .EXAMPLE
            Export-QualysReportTemplate -qualysServer $server -cookie $cookie -templateID 987654 -full | Out-file Testing.xml

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will return an xml in plaintext that has all the information on the Template with ID 987654. Piping it into Out-File will right the raw xml`
             data to the document Testing.xml.

    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie,

        [Parameter()]
        [string]$templateID,

        [Parameter()]
        [switch]$full
    )

    Begin{}
    Process
    {
        $actionBody = @{
            action = "export"
            report_format = "xml"
        }
        if($templateID){
            $actionBody.Add("template_id",$templateID)
        }
        if($full){
            $response = Invoke-WebRequest -Headers @{"X-Requested-With"="powershell"} -Uri "https://$qualysServer/api/2.0/fo/report/template/scan/" -Method Get -Body $actionBody -WebSession $cookie
            $response.Content
        }
        else{
            $response = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -Uri "https://$qualysServer/api/2.0/fo/report/template/scan/" -Method Get -Body $actionBody -WebSession $cookie
            $root = $response.REPORTTEMPLATE.SCANTEMPLATE
            $newobj = @()
            if($templateID){
                $root
            }
            else{
                foreach($template in $root){
                    $object = New-Object PSObject -Property @{
                        Title = $template.Title.INFO[1].'#cdata-section'
                        ID = $template.Title.INFO[0].'#cdata-section'
                        SearchlistID = $template.REPORTTEMPLATE.SCANTEMPLATE.Filter.Info[1].'#cdata-section'
                        #can add more properties here, but the title and ID are the bare minimum. May add more in the future should the need arise.
                    }
                    $newobj += $object
                }
            $newobj
            }
        }
    }
    End{}
}