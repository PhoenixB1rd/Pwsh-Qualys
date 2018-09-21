function Connect-Qualys {
    <#
        .Synopsis
        Connect to Qualys API and get back session $cookie for all other functions

        .DESCRIPTION
            Connect to Qualys API and get back session $cookie for all other functions.

        .PARAMETER qualysCred
            use Get-Credential to create a PSCredential with the username and password of an account that has access to Qualys

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER assetTagging
            There are two different api endpoints, the new one is Asset Management and Tagging.  Use this switch to get a cookie to make calls to Asset Management and Tagging

        .EXAMPLE
            $cookie = Connect-Qualys -qualysCred $qualysCred -qualysServer $server

            The variables $server is the qualys API Url that you wish to use.

            Will retreive a websession object that can be used in the $cookie variable in most other Qualys functions, unless the function specifies AssetTagging cookie.

        .EXAMPLE
            $cookie2 = Connect-Qualys -qualysCred $qualysCred -qualysServer $server -assetTagging

            The variables $server is the qualys API Url that you wish to use.

            Will retreive a websession object using credentials that are base64 encoded. Which can be used in the $cookie variable in other Qualys functions that ask for an AssetTagging cookie.

        .Notes
            Author: Travis Sobeck, Kyle Weeks
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$qualysCred,

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [switch]$assetTagging

    )

    Begin{}
    Process
    {
        $qualysuser = $qualysCred.UserName
        $qualysPswd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($qualysCred.Password))

        if ($assetTagging)
        {
            $auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($qualysuser+':'+$qualysPswd))
            $header += @{"Authorization" = "Basic $auth"}
            $response = Invoke-RestMethod -Uri "https://$qualysServer/qps/rest/portal/version" -Method GET -SessionVariable cookie -Headers $header
            return $cookie

        }
        else
        {
            ############# Log in #############
            ## URL for Logging In/OUT

            ## Login/out
            $logInBody = @{
                action = "login"
                username = $qualysuser
                password = $qualysPswd
            }

            ## Log in SessionVariable captures the cookie
            $uri = "https://$qualysServer/api/2.0/fo/session/"
            $response = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -Uri $uri -Method Post -Body $logInBody -SessionVariable cookie
            return $cookie
        }

    }
    End{}
}