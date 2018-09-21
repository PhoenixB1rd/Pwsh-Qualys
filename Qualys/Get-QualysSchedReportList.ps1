function Get-QualysSchedReportList{
    <#
        .Synopsis
            Get a list of Reports Scheduled.

        .DESCRIPTION
            Get a list of Reports Scheduled. Data received will include which day of the week,or day of month the report is set to run on.

        .PARAMETER id
            (Optional) Report Schedule ID

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie

        .EXAMPLE
            Get-QualysSchedReportList -qualysServer $server -cookie $cookie

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            Will return a list of all the Qualys Reports and their schedules

        .EXAMPLE
            Get-QualysSchedReportList -qualysServer $server -cookie $cookie -id 123455

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            Will return a information regarding id 123455
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
        $actionBody = @{
            action = "list"
        }
        if($id){
            $actionBody.add("id",$id)
        }
        [xml]$returnedXML = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -Uri "https://$qualysServer/api/2.0/fo/schedule/report" -Method Get -Body $actionBody -WebSession $cookie
        $data = $returnedXML.SCHEDULE_REPORT_LIST_OUTPUT.RESPONSE.SCHEDULE_REPORT_LIST.REPORT
        $newlist = @()
        #make this data pretty and useable for csv purposes
        foreach ($obj in $data){
        $newlist += New-Object PSObject -Property @{
            Title = $obj.TITLE.'#cdata-section'
            ID = $obj.ID
            Template = $obj.TEMPLATE_TITLE.'#cdata-section'
            Active = $obj.ACTIVE
            Monthly_day = $obj.SCHEDULE.MONTHLY.day_of_month
            Weekly_day = $obj.SCHEDULE.WEEKLY.weekdays
            Daily_day =$obj.SCHEDULE.Daily.frequency_days
            StartDate = $obj.SCHEDULE.Start_DATE_UTC
            StartHour = $obj.SCHEDULE.Start_Hour
            StartMinute = $obj.SCHEDULE.Start_Minute
            TimeZone = $obj.SCHEDULE.Time_Zone.TIME_Zone_CODe
            }
        }
        $newlist
    }
    End{}
}