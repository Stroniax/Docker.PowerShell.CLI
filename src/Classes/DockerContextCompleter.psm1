using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using module ../Private/ConvertTo-CompletionText.psm1
using module ../Private/ConvertTo-WordToCompleteWildcard.psm1

class DockerContextCompleter : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string]$commandName,
        [string]$parameterName,
        [string]$wordToComplete,
        [CommandAst]$commandAst,
        [IDictionary]$fakeBoundParameters
    ) {
        $wc = ConvertTo-WordToCompleteWildcard -WordToComplete $wordToComplete

        Write-Debug 'docker context list --quiet'
        $Contexts = docker context list --quiet
        Write-Debug 'docker context show'
        $CurrentContext = docker context show

        $Results = [List[CompletionResult]]::new()
        foreach ($Context in $Contexts) {
            if ($Context -notlike $wc) {
                continue
            }
            if ($Context -eq $CurrentContext) {
                $DisplayText = "$($global:PSStyle.Foreground.BrightCyan)$Context$($global:PSStyle.Reset)"
            }
            else {
                $DisplayText = $Context
            }
            $CompletionText = ConvertTo-CompletionText -InputObject $Context -WordToComplete $wordToComplete
            $Results.Add(
                [CompletionResult]::new(
                    $CompletionText,
                    $DisplayText,
                    'ParameterValue',
                    $DisplayText
                )
            )
        }
        return $Results
    }
}
