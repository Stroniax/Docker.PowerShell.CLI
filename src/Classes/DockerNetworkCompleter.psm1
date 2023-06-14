using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using module ../Private/ConvertTo-CompletionText.psm1
using module ../Private/ConvertTo-WordToCompleteWildcard.psm1

class DockerNetworkCompleter : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [CommandAst] $CommandAst,
        [IDictionary] $FakeBoundParameters
    ) {
        $wc = ConvertTo-WordToCompleteWildcard -WordToComplete $WordToComplete
        $CompletionResults = [List[CompletionResult]]::new()

        $DockerNetworkParameters = @{}
        if ($FakeBoundParameters['Context']) {
            $DockerNetworkParameters['Context'] = $FakeBoundParameters['Context']
        }
        
        $networks = Get-DockerNetwork @DockerNetworkParameters

        foreach ($network in $networks) {
            $IsMatch = $false
            $RawCompletionText = ''
            switch ($ParameterName) {
                { $_ -in @('Id', 'NetworkId') } {
                    $IsMatch = $network.Id -like $wc
                    $RawCompletionText = $network.Id
                }
                'Driver' {
                    $IsMatch = $network.Driver -ne 'null' -and $network.Driver -like $wc
                    $RawCompletionText = $network.Driver
                }
                'Scope' {
                    $IsMatch = $network.Scope -like $wc
                    $RawCompletionText = $network.Scope
                }
                default {
                    $IsMatch = $network.Name -like $wc
                    $RawCompletionText = $network.Name
                }
            }
            if (!$IsMatch) {
                continue
            }

            $CompletionText = ConvertTo-CompletionText -InputObject $RawCompletionText -WordToComplete $WordToComplete

            $CompletionResults.Add(
                [CompletionResult]::new(
                    $CompletionText,
                    $RawCompletionText,
                    'ParameterValue',
                    $RawCompletionText
                )
            )
        }
        
        return $CompletionResults
    }
}