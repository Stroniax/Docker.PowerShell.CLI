using namespace System.Collections;
using namespace System.Diagnostics;
using namespace System.Collections.Generic;
using namespace System.Management.Automation;
using namespace System.Management.Automation.Language;

class DockerContextCompleter : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string]$commandName,
        [string]$parameterName,
        [string]$wordToComplete,
        [CommandAst]$commandAst,
        [IDictionary]$fakeBoundParameters
    ) {
        if ($null -eq $wordToComplete) {
            $wordToComplete = ''
        }
        $wc = $wordToComplete.Trim('"''') + '*'

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
            $Results.Add(
                [CompletionResult]::new(
                    $Context,
                    $DisplayText,
                    'ParameterValue',
                    $DisplayText
                )
            )
        }
        return $Results
    }
}
