function Get-QualysReportTemplate{
    <#
        .Synopsis
            Get a list of the Qualys Report Templates in order to get information on them or their ID for the use in other functions.

        .DESCRIPTION
            Get a list of the Qualys Report Templates in order to get information on them or their ID for the use in other functions.

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER Assetcookie
            Use Connect-Qualys to get session cookie that can be used with their legacy API by setting the -AssetTagging when creating the cookie.

        .EXAMPLE
            Get-QualysReportTemplate -qualysServer $server -assetCookie $cookie2

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will retrieve a full list of Report Templates that are within the Qulays Subscription. It is suggested that the output is stored in a variable for further data `
            manipulation.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$assetCookie
    )

    Begin{}
    Process
    {
        $templates = [xml]$Templates = Invoke-WebRequest -Uri "https://qualysapi.qualys.com/msp/report_template_list.php" -Method GET -WebSession $assetCookie
        $newlist = @()
        foreach($template in $templates.REPORT_TEMPLATE_LIST.REPORT_TEMPLATE){
            $NEWobj = New-Object PSObject -Property @{
                ID = $template.ID
                TYPE = $template.TYPE
                TEMPLATE_TYPE = $template.TEMPLATE_TYPE
                TITLE = $template.TITLE.'#cdata-section'
                USER = $template.USER.Login.'#cdata-section'
                LAST_UPDATE = $template.LAST_UPDATE
                GLOBAL = $template.GLOBAL
            }
            $newlist += $NEWobj
        }
        $newlist
    }
    End{}
}