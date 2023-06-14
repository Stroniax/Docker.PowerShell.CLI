using namespace System.Collections;
using namespace System.Diagnostics;
using namespace System.Collections.Generic;
using namespace System.Management.Automation;
using namespace System.Management.Automation.Language;
class DockerContainerCompleter : IArgumentCompleter {
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
        $ProxyParameters = @{}
        if ($FakeBoundParameters['Context']) {
            $ProxyParameters['Context'] = $FakeBoundParameters['Context']
        }

        $Containers = Get-DockerContainer @ProxyParameters

        $CompletionResults = [List[CompletionResult]]::new();
        foreach ($Container in $Containers) {
            $IsMatch = $Container.Names -like $wc -or $Container.id -like $wc
            if (-not $IsMatch) {
                continue
            }

            if ($parameterName -in 'ContainerId', 'Id') {
                $CompletionText = @($Container.Id)
            }
            else {
                $CompletionText = @($Container.Names)
            }

            foreach ($Completion in $CompletionText) {
                $HasUnsafeChar = $Completion.IndexOfAny("`0`n`r`t`v`'`"`` ".ToCharArray()) -ge 0
                $SafeCompletionText = if ($HasUnsafeChar) { "'$Completion'" } else { $Completion }
                $ListItemText = if ($Completion -eq $Container.Id) { "$Completion (name: $($Container.Names -join ', '))" } else { "$Completion (id: $($Container.Id))" }

                $CompletionResults.Add(
                    [CompletionResult]::new(
                        $SafeCompletionText,
                        $ListItemText,
                        'ParameterValue',
                        $Completion
                    )
                )
            }
        }

        return $CompletionResults
    }
}