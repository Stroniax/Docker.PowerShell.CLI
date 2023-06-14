using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections.Generic
using namespace System.Collections

class NumericArgumentCompleter : IArgumentCompleter {
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

        return [CompletionResult[]]@(
            [CompletionResult]::new(1, 1, 'ParameterValue', 1)
            [CompletionResult]::new(2, 2, 'ParameterValue', 2)
            [CompletionResult]::new(3, 3, 'ParameterValue', 3)
            [CompletionResult]::new(4, 4, 'ParameterValue', 4)
            [CompletionResult]::new(5, 5, 'ParameterValue', 5)
            [CompletionResult]::new(6, 6, 'ParameterValue', 6)
            [CompletionResult]::new(7, 7, 'ParameterValue', 7)
            [CompletionResult]::new(8, 8, 'ParameterValue', 8)
            [CompletionResult]::new(9, 9, 'ParameterValue', 9)
            [CompletionResult]::new(10, 10, 'ParameterValue', 10)
        )
    }
}