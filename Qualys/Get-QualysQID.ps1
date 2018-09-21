function Get-QualysQID{
        <#
            .Synopsis
                Find Vulnerable Assets with a specifc CVE or QUID

            .DESCRIPTION
                Find Vulnerable Assets with a specifc CVE or QUID

            .PARAMETER qualysServer
                Specify the Qualys server to be queried

            .PARAMETER cookie
                Provide the Web Session used to connect to Qualys from the Connect-Qualys command

            .PARAMETER qID
                ID of the Dynamic Search List that you wish to query

            .PARAMETER patchable
                To show only QIDS that have patches out

            .PARAMETER raw
                Switch that will give you the raw output from the qualys API, unfiltered or unedited.

            .PARAMETER all
                Use this switch instead of providing a specific QID to get a list of all QIDs in the Qualys `
                Knowledge Base.

            .PARAMETER outfile
                When the data becomes too large to handle within a powershell session. The data can be placed in a file and taken out of memory, in a way throttling the script.

            .EXAMPLE
                $data = Get-QualysQID -qualysServer $server -cookie $cookie -qID 45038 -raw

                The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

                This will return the raw API response from Qualys into the variable $data so that the data can be transversed using xml object handling that is integrated into poweshell.

            .EXAMPLE
                Get-QualysQID -qualysServer $server -cookie $cookie -qID 45038

                The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

                Will return basic information on the QID 45038 if it exists. More information can be retrieved with using the -raw switch.

            .EXAMPLE
                $allQids = Get-QualysQID -qualysServer $server -cookie $cookie -all

                The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

                This will return all QIDs within the Qualys Knowledge Base and place it in the variable $allQids

                Note: This method might crash the powershell shell due to memory allocations for the shell issues. The shell can be given more memory at runtime, but that how-to is out`
                 of the scope of this help. Instead I suggest using Example 3.

            .EXAMPLE
                Get-QualysQID -qualysServer $server -cookie $cookie -all -outfile Exampledocument.csv

                The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

                This will return all QIDs within the Qualys Knowledge Base and place it in the specified file in a csv format.

            .EXAMPLE
                Get-QualysQID -qualysServer $server -cookie $cookie -all -outfile Exampledocument.csv

                The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

                This will return all QIDs within the Qualys Knowledge Base that has a Remote value of "1" and place it in the specified file in a csv format.
        #>
        [CmdletBinding()]
        Param
        (
            [Parameter(Mandatory)]
            [string]$qualysServer,

            [Parameter(Mandatory)]
            [Microsoft.PowerShell.Commands.WebRequestSession]$cookie,

            [Parameter(ParameterSetName = "qids",Mandatory = $true)]
            [int[]]$qID,

            [Parameter()]
            [switch]$patchable,

            [Parameter()]
            [switch]$raw,

            [Parameter(ParameterSetName = "all",Mandatory = $true)]
            [switch]$all,

            [Parameter(ParameterSetName = "all")]
            [switch]$remote,

            [Parameter(ParameterSetName = "all")]
            [string]$outfile

        )

        Begin{}
        Process
        {
            if($all){
                $actionBody = @{
                    action = "list"
                    details = "All"
                }
            }
            else{
                $actionBody = @{
                action = "list"
                details = "All"
                ids = $qID -join ","
                }
            }


            if($patchable){
                $actionBody.add('is_patchable',1)
            }
            if($remote){
                $actionBody.add('discovery_method','Remote')
            }

            [xml]$xmlResponse = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -URI "https://$qualysServer/api/2.0/fo/knowledge_base/vuln/" -Method POST -WebSession $cookie -Body $actionBody
            $data = $xmlResponse.KNOWLEDGE_BASE_VULN_LIST_OUTPUT.RESPONSE.VULN_LIST.Vuln

            if($raw){
                $xmlResponse
            }
            elseif($outfile){

                $z=0
                foreach($obj in $data){
                    $value = $obj.DIAGNOSIS.'#cdata-section'
                    if(($preQIDinfo = $value.Split('QID Detection Logic')[1])){
                        $QIDinfo = $preQIDinfo.replace('<BR>',"")
                    }
                    else{
                        $QIDinfo = $obj.DIAGNOSIS.'#cdata-section'
                    }
                    if($QId.QID_Detection_Logic -match "`n"){
                        $QId.QID_Detection_Logic.Replace("`n"," ")
                    }

                    $newhash = [pscustomobject]@{
                    Qid = $obj.QID
                    Title = $obj.TITLE.'#cdata-section'
                    Severity = $obj.Severity_level
                    Published = $obj.Published_datetime
                    Patchable = $obj.patchable
                    CVEs = $obj.CVE_LIST.CVE.ID.'#cdata-section'
                    QID_Detection_Logic = $QIDinfo
                    Exploit_ref = $obj.CORRELATION.Exploits.EXPLT_SRC.EXPLT_LIST.EXPLT.REf.'#cdata-section'
                    Exploit_Description = $obj.CORRELATION.Exploits.EXPLT_SRC.EXPLT_LIST.EXPLT.DESC.'#cdata-section'
                    Remote = $obj.Discovery.Remote
                    Auth_Type = $obj.DISCOVERY.AUTH_TYPE_LIST.AUTH_TYPE
                    }

                    $newhash | Export-csv -Path $outfile -Append

                    $z++
                    if($data.count){
                    Write-Progress -Activity "Converting QID results to usable data" -Status "QID $z of $($data.count)" -PercentComplete (($z / $data.count) * 100 )
                    }
                }
            }
            else {
                $masterlist = @()
                $z=0
                foreach($obj in $data){
                    $value = $obj.DIAGNOSIS.'#cdata-section'
                    if(($preQIDinfo = $value.Split('QID Detection Logic')[1])){
                        $QIDinfo = $preQIDinfo.replace('<BR>',"")
                    }
                    else{
                        $QIDinfo = $obj.DIAGNOSIS.'#cdata-section'
                    }
                    if($QId.QID_Detection_Logic -match "`n"){
                        $QId.QID_Detection_Logic.Replace("`n"," ")
                    }

                    $newhash = [pscustomobject]@{
                    Qid = $obj.QID
                    Title = $obj.TITLE.'#cdata-section'
                    Severity = $obj.Severity_level
                    Published = $obj.Published_datetime
                    Patchable = $obj.patchable
                    CVEs = $obj.CVE_LIST.CVE.ID.'#cdata-section'
                    QID_Detection_Logic = $QIDinfo
                    Exploit_ref = $obj.CORRELATION.Exploits.EXPLT_SRC.EXPLT_LIST.EXPLT.REf.'#cdata-section'
                    Exploit_Description = $obj.CORRELATION.Exploits.EXPLT_SRC.EXPLT_LIST.EXPLT.DESC.'#cdata-section'
                    Remote = $obj.Discovery.Remote
                    Auth_Type = $obj.DISCOVERY.AUTH_TYPE_LIST.AUTH_TYPE
                    }
                    $masterlist += $newhash
                    $z++
                    if($data.count){
                        Write-Progress -Activity "Converting QID results to usable data" -Status "QID $z of $($data.count)" -PercentComplete (($z / $data.count) * 100 )
                        }
                }

                [pscustomobject]$masterlist

            }
        }
        End{}
    }