function Find-VulnerableAssets {
    ##
    ##
    ##
    ## WORK IN PROGRESS - Finding errors when creating a new report template... but the template is still created. Maybe there is a way to check if the template was created or not. . .
    ##
    ##
    ##
        <#
            .Synopsis
                Find Vulnerable Assets with a specifc CVE or QUID

            .DESCRIPTION
                Find Vulnerable Assets with a specifc CVE or QUID

            .PARAMETER
                ID of a host

            .PARAMETER
        #>
        [CmdletBinding(DefaultParameterSetName= 'CVE')]
        Param
        (
            [Parameter(ParameterSetName='CVE')]
            [string]$cVE,

            [Parameter(ParameterSetName='QUID')]
            [string]$qUID,

            [Parameter(Mandatory=$true)]
            [string]$assetGroup,

            [Parameter(Mandatory=$true)]
            [string]$qualysServer,

            [Parameter(Mandatory=$true)]
            [Microsoft.PowerShell.Commands.WebRequestSession]$cookie,

            [Parameter(Mandatory=$true)]
            [Microsoft.PowerShell.Commands.WebRequestSession]$assetCookie,

            [Parameter(Mandatory=$true)]
            [string]$title,

            # Subscription ID for the Qualys account you are trying to use.
            [Parameter(Mandatory=$true)]
            [string]$subscriptionID,

            # IF you didn't want to query cloud data for the results and wanted a fresh scan, use this switch to start the scan.
            [Parameter(ParameterSetName="Scan")]
            [switch]$scan,

            # Priority for the Scan if the Scan switch is used
            [Parameter(ParameterSetName="Scan")]
            [ValidatePattern('^[0-9]$')]
            [string]$priority
        )

        Begin{}
        Process
        {
            if($cVE){
                   $Splatting = @{
                    title = $title
                    CVE = $cVE
                    qualysServer = $qualysServer
                    cookie = $cookie
                }
            }
            else {
                $Splatting = @{
                    title = $title
                    QUID = $qUID
                    qualysServer = $qualysServer
                    cookie = $cookie
                }
            }

            #Create Dynamic SearchList and store the ID in a variable
            $listID = New-QualysDynamicSearchList @Splatting -global
            Write-Verbose "Created the dynamic list $listID"

            #Create Report template
            $reportTemplate = New-QualysReportTemplate -qualysServer $qualysServer -assetCookie $assetCookie -title $title -templateDoc "$PSScriptRoot/ReportTemplateTemplate.xml" -searchlistID $listID
            $reportTemplateID = $reportTemplate.ID
            Write-Verbose "Template was created $($reportTemplate.ID) please check"

            if($reportTemplateID.length -eq 0){
                Write-Verbose "It appears the template did not create properly, waiting a minute to query again."
                Start-Sleep -Seconds  60
                $reporttempcheck = Get-QualysReportTemplate -qualysServer $server -assetCookie $assetCookie | Where {$_.Title -eq "$title"}
                $reportTemplateID = $reporttempcheck.ID
                Write-Verbose "Template was found, this is the ID $reportTemplateID"
            }

            #Create Options profile for scans only
            if($scan){
                Write-Verbose "Scan sequence has been initiated"
                $optionprofile = New-QualysOptionProfile -qualysServer $qualysServer -cookie $cookie -templateDoc "$PSScriptRoot/OptionProfileTemplate.xml" -name $title `
                -subscriptionID $subscriptionID -portScanType Standard -searchlistID $listID -searchlistName $title
                Write-Verbose "Option profile was created $optionprofile"

                $NewScan = New-QualysScan -qualysServer $qualysServer -cookie $cookie -scantitle $title -optionProfileID $optionprofile -priority $priority -AssetGroupName $assetGroup
                $ref = $NewScan.scanRefID
                #get the status of the scan and wait for it to finish
                Write-Verbose "New Scan was initiated $NewScan"

                $data = Get-QualysScanList -qualysServer $qualysServer -cookie $cookie -scanRef $ref
                Write-Verbose "First check on the status is $($data.status)"
                while($data.status -eq "Running"){
                    Start-Sleep -Seconds 300
                    Write-verbos "Sleeping for 5 minutes"
                    $data = Get-QualysScanList -qualysServer $qualysServer -cookie $cookie -id $reportID
                    Write-Verbose "Checking status and the status is $($data.status)"
                }
                Write-Verbose "Exiting the while loop and onto creating the report"

                #Create Report for Scan
                $reportResults = New-QualysReport -templateID $reportTemplate -title $title -qualysServer $qualysServer -cookie $cookie -assetgroup $assetGroup -outputFormat csv -reportType Scan `
                -scanRefID $ref
                $reportID = $reportResults.ID
                Write-Verbose "Report was created with ID $reportID"
            }
            else{
                #Create Report
                $results = New-QualysReport -templateID $reportTemplateID -title $title -qualysServer $qualysServer -cookie $cookie -assetgroup $assetGroup -outputFormat csv -reportType Scan
                $reportID = $results.ID
                Write-Verbose "$results"
            }



            #Check to see if report is ready, if not the script will wait until it is ready.
            $response = Get-QualysReportList -qualysServer $qualysServer -cookie $cookie -id $reportID
            Write-Verbose "Current report status $($reponse.status.state)"
            while($reponse.status.state -eq "Running"){
                Write-Verbose "Starting to wait for 300 seconds."
                Start-Sleep -Seconds  300
                $response = Get-QualysReportList -qualysServer $qualysServer -cookie $cookie -id $reportID
                Write-Verbose "Current report status $($reponse.status.state)"
            }
            if($reponse.status.state -eq "Finished"){
                Write-Verbose "Report is now finished. $($response.status.state)"
                Get-QualysReport -qualysServer $qualysServer -cookie $cookie -id $reportID -outfile ./
                Write-Verbose "Look for the file that was created in the current directory."
            }
            else{
                $response.status.state
            }

            #clean up
            Remove-QualysDynamicSearchList -qualysServer $qualysServer -cookie $cookie -id $listID -force
            Write-Verbose "Cleaned up the DynamicSearchList that was created. Will need to clean up the template and report if you want."
        }
        End{}
    }