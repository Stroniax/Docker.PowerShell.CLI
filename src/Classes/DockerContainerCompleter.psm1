using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using module ../Private/ConvertTo-CompletionText.psm1
using module ../Private/ConvertTo-WordToCompleteWildcard.psm1

class DockerContainerCompleter : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string]$commandName,
        [string]$parameterName,
        [string]$wordToComplete,
        [CommandAst]$commandAst,
        [IDictionary]$fakeBoundParameters
    ) {
        $wc = ConvertTo-WordToCompleteWildcard $wordToComplete
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
                $SafeCompletionText = ConvertTo-CompletionText -InputObject $Completion -WordToComplete $wordToComplete
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