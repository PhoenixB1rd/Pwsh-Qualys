function Remove-QualysDynamicSearchList{
    <#
        .Synopsis
            Delete a Dynamic Search List by its ID, if you don't know the ID of the dynamic search list, than it cannot be deleted via API. Sorry.

        .DESCRIPTION
            Delete a Dynamic Search List by its ID, if you don't know the ID of the dynamic search list, than it cannot be deleted via API.

        .PARAMETER qualysServer
            Specify the Qualys server to be queried

        .PARAMETER cookie
            Provide the Web Session used to connect to Qualys from the Connect-Qualys command

        .PARAMETER id
            Id of the dynamic searchlist that you wish to delete

        .EXAMPLE
            Remove-QualysDynamicSearchList -qualysServer $server -cookie $cookie -id 11234567

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This function will check if the ID provided does exist, if it exists.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie,

        [Parameter(Mandatory)]
        [string]$id,

        #for when you don't want to be prompted, like in automation
        [Parameter()]
        [switch]$force

    )

    Begin{}
    Process
    {

        #check if exists
        $data = Get-QualysDynamicSearchList -qualysServer $qualysServer -cookie $cookie -id $id
        if($data){
            $name = $data.title.'#cdata-section'
            if($force =! $false){
                #prompt to clarify
                $answer = Read-Host -Prompt "Are you sure you want to remove the dynamic Searchlist $($name)?[y/n]"
                if($answer -ne "y"){
                    Throw "Aborted the script"
                }
            }
            $actionBody = @{
                action = "delete"
                id = $id
            }

            [xml]$response = Invoke-RestMethod -Headers @{"X-Requested-With"="powershell"} -URI "https://$qualysServer/api/2.0/fo/qid/search_list/dynamic/" -Method Post -WebSession $cookie -Body $actionBody
            $response.SIMPLE_RETURN.RESPONSE.text
        }
        else{
            Throw "That Dynamic Search ID was not found in the Qualys Subscription"
        }

    }
    End{}
}