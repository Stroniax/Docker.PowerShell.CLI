using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections.Generic
using namespace System.Collections

class EmptyHashtableArgumentCompleter : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string]$commandName,
        [string]$parameterName,
        [string]$wordToComplete,
        [CommandAst]$commandAst,
        [IDictionary]$fakeBoundParameters
    ) {
        if ($wordToComplete) {
            return [CompletionResult[]]::new(0)
        }

        return [CompletionResult[]]@(
            [CompletionResult]::new('@{}', '@{} # empty hashtable', 'ParameterValue', '@{} # empty hashtable')
        )
    }
}