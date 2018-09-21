function Import-QualysOptionProfile{
    <#
        .Synopsis
            Find Vulnerable Assets with a specifc CVE or QUID

        .DESCRIPTION
            Find Vulnerable Assets with a specifc CVE or QUID

        .PARAMETER qualysServer
            Specify the Qualys server to be queried

        .PARAMETER cookie
            Provide the Web Session used to connect to Qualys from the Connect-Qualys command

        .PARAMETER file
            Provide the template file that one wishes to use to import into Qualys. One is included in the module labeled`
            OptionProfileTemplate.ps1

        .EXAMPLE
            Import-QualysOptionProfile -qualysServer $server -cookie $cookie -file ./OptionProfileTemplate.xml

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will import the file specified as an option profile within the Qualys Subscription.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie,

        [Parameter(Mandatory)]
        [string]$file
    )

    Begin{}
    Process
    {
        $filecontent = get-content $file
        $data = Invoke-RestMethod -ContentType 'text/xml' -Headers @{"X-Requested-With"="powershell"} -URI "https://$qualysServer/api/2.0/fo/subscription/option_profile/?action=import" -Body $filecontent -Method Post -WebSession $cookie
        $data.SIMPLE_RETURN.RESPONSE.Text

    }
    End{}
}