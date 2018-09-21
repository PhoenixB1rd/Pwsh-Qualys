function Search-QualysQID{
    <#
        .Synopsis
            Find the QUID(s) associated with a keyword or a CVE

        .DESCRIPTION
            Find the QUID(s) associated with a keyword or a CVE

        .PARAMETER keyword
            Keywords that might match the title of a QUID that can be searched upon

        .PARAMETER cVE
            Searching for QUID(s) associated with a specific CVE(s)

        .PARAMETER qualysServer
            FQDN of qualys server, see Qualys documentation, based on wich Qualys Platform you're in.

        .PARAMETER cookie
            Use Connect-Qualys to get session cookie

        .EXAMPLE
            Search-QualysQID -qualysServer $server -cookie $cookie -cVE CVE-2018-5924

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This function will search for QIDs that are associated with the CVE CVE-2018-5924.

        .EXAMPLE
            Search-QualysQID -qualysServer $server -cookie $cookie -keyWord "Inkjet"

            The variables $server is the qualys API Url that you wish to use. The $cookie variable is the output captured from Connect-Qualys script.

            This will search for a QID using the keyWord "Inkjet".


    #>

    [CmdletBinding(DefaultParameterSetName= 'CVE')]
    Param
    (

        [Parameter(ParameterSetName='CVE')]
        [string[]]$cVE,

        [Parameter(ParameterSetName='KeyWord')]
        [string]$keyWord,

        [Parameter(Mandatory)]
        [string]$qualysServer,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$cookie

    )

    Begin{}
    Process{

        #creating splatting for common parameters
        $Common = @{
            qualysServer = $qualysServer
            cookie = $cookie
        }
        if($cVE){
            $Creation = @{
                cVE = $cVE -join ","
                title = $cVE -join ","
            }
        }
        else {
            $Creation = @{
                title = $keyWord
                keyword = $keyWord
            }
        }

        #make a new searchlist to find the QIDs
        $id = New-QualysDynamicSearchList @Common @Creation

        #get the searchlist information after it was created.
        $searchlist = Get-QualysDynamicSearchList -id $id @Common

        #seperating out the QIDS
        $QIDS = $searchlist.QIDS.QID

        #Cleanup
        $removedata = Remove-QualysDynamicSearchList -id $id @Common -force
        Write-Verbose "Results of remove command $($removedata.text) $($removedata.Itemlist.Item)"

        $QIDS
    }

    End{}

}