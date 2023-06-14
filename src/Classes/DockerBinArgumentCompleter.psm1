using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections
using namespace System.Collections.Generic
using module ../Private/ConvertTo-WordToCompleteWildcard.psm1
using module ../Private/ConvertTo-CompletionText.psm1

class DockerBinArgumentCompleter : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string] $commandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [CommandAst] $commandAst,
        [IDictionary] $fakeBoundParameters) {
        $wc = ConvertTo-WordToCompleteWildcard -WordToComplete $wordToComplete

        $DockerContainerParameters = @{}
        if ($FakeBoundParameters.ContainsKey('Context')) {
            $DockerContainerParameters['Context'] = $FakeBoundParameters['Context']
        }
        if ($FakeBoundParameters.ContainsKey('Id')) {
            $DockerContainerParameters['Id'] = $FakeBoundParameters['Id']
        }
        if ($FakeBoundParameters.ContainsKey('Name')) {
            $DockerContainerParameters['Name'] = $FakeBoundParameters['Name']
        }

        $Container = Get-DockerContainer @DockerContainerParameters
        if (!$?) { return [CompletionResult[]]::new(0) }
        if (!$Container) { return [CompletionResult[]]::new(0) }

        $DockerArguments = @(
            if ($FakeBoundParameters['Context']) { '--context'; $FakeBoundParameters['Context'] }
            'exec'
            '-w'
            '/bin'
            '-t'
            $Container.Id
            'ls'
            '--format=single-column'
        )

        Write-Debug "docker $DockerArguments"
        $BinContents = docker $DockerArguments
        if (!$?) { return [CompletionResult[]]::new(0) }

        $Completions = [List[CompletionResult]]::new($BinContents.Count)
        foreach ($item in $BinContents) {
            if ($Item -like $wc) {
                $CompletionText = ConvertTo-CompletionText -InputObject $Item -WordToComplete $wordToComplete
                $Completions.Add([CompletionResult]::new($CompletionText, $Item, 'ParameterValue', $Item))
            }
        }

        return $Completions
    }

}