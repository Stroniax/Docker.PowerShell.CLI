using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections.Generic
using namespace System.Collections

class DateTimeArgumentCompleter : IArgumentCompleter {
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

        $CompletionResults = [CompletionResult[]]::new(10)

        for ($i = 0; $i -lt $CompletionResults.Count; $i++) {
            $Date = [DateTime]::Today.AddDays(-$i)
            $DateString = $Date.ToString('yyyy-MM-dd')
            $CompletionResults[$i] = [CompletionResult]::new($DateString, $DateString, 'ParameterValue', $DateString)
        }

        return $CompletionResults
    }
}