using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections.Generic
using namespace System.Collections

class BooleanArgumentCompleter : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string]$commandName,
        [string]$parameterName,
        [string]$wordToComplete,
        [CommandAst]$commandAst,
        [IDictionary]$fakeBoundParameters
    ) {
        if ($wordToComplete) {
            return [Immutable.ImmutableList[CompletionResult]]::Empty
        }

        $CompletionResults = [List[CompletionResult]]::new(3)
        $CompletionResults.Add([CompletionResult]::new('$true', 'true', 'ParameterValue', 'true'))
        $CompletionResults.Add([CompletionResult]::new('$false', 'false', 'ParameterValue', 'false'))

        $Command = Get-Command -Name $commandAst.GetCommandName()
        $Parameter = $Command.Parameters[$parameterName]
        if ($Parameter.ParameterType -eq [Nullable[bool]]) {
            $CompletionResults.Add([CompletionResult]::new('$null', 'null', 'ParameterValue', 'null'))
        }
        
        return $CompletionResults
    }
}