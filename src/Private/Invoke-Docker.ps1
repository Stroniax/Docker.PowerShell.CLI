using namespace System.Collections.Generic
using module ../Classes/ValidateDockerContext.psm1

$Docker = (Get-Command 'docker' -ErrorAction Stop).Path
function Invoke-Docker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromRemainingArguments)]
        [string[]]
        $ArgumentList,

        [Parameter()]
        [ValidateDockerContext()]
        [string]
        $Context
    )

    process {
        $List = [List[string]]$ArgumentList
        if ($Context) {
            $List.Insert(0, '--context')
            $List.Insert(1, $Context)
        }
        Write-Debug "$Docker $List"
        & $Docker $List
    }
}