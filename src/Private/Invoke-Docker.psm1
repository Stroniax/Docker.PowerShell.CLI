using namespace System.Collections.Generic
using namespace System.Management.Automation
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
        
        # Report errors as PowerShell error stream errors
        & $Docker $List 2>&1 | ForEach-Object {
            if ($_ -is [ErrorRecord]) {
                if ($_.Exception.ErrorRecord.Exception.Message -eq '') {
                    return
                }
                $WriteError = @{
                    Exception        = $_.Exception
                    Category         = [ErrorCategory]::FromStdErr
                    CategoryActivity = $MyInvocation.MyCommand.Name
                    ErrorId          = 'DockerCliError'
                    TargetObject     = $List.ToArray()
                }
                Write-Error @WriteError
            }
            else {
                $_
            }
        }
    }
}