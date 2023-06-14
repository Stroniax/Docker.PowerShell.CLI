using namespace System.Collections;
using module src/Classes/ValidateDockerContext.psm1

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
        Write-Debug "docker $List"
        docker $List
    }
}