using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using module ../Private/ConvertTo-CompletionText.psm1
using module ../Private/ConvertTo-WordToCompleteWildcard.psm1

class DockerVolumeCompleter : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [CommandAst] $CommandAst,
        [IDictionary] $FakeBoundParameters
    ) {
        $wc = ConvertTo-WordToCompleteWildcard -WordToComplete $WordToComplete
        $CompletionResults = [List[CompletionResult]]::new()

        $DockerVolumeParameters = @{}
        if ($FakeBoundParameters['Context']) {
            $DockerVolumeParameters['Context'] = $FakeBoundParameters['Context']
        }
        if ($WordToComplete -notin @('Driver', 'Scope', 'Group')) {
            $DockerVolumeParameters['Name'] = $wc
        }
        
        $volumes = Get-DockerVolume @DockerVolumeParameters -ErrorAction Ignore

        foreach ($volume in $volumes) {
            $IsMatch = $false
            $RawCompletionText = ''
            switch ($ParameterName) {
                'Driver' {
                    $IsMatch = $volume.Driver -like $wc
                    $RawCompletionText = $volume.Driver
                }
                'Scope' {
                    $IsMatch = $volume.Scope -like $wc
                    $RawCompletionText = $volume.Scope
                }
                'Group' {
                    $IsMatch = $volume.Group -like $wc
                    $RawCompletionText = $volume.Group
                }
                default {
                    $IsMatch = $volume.Name -like $wc
                    $RawCompletionText = $volume.Name
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