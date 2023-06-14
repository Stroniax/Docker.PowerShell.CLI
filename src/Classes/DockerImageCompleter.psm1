using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using module ../Private/ConvertTo-CompletionText.psm1
using module ../Private/ConvertTo-WordToCompleteWildcard.psm1

class DockerImageCompleter : IArgumentCompleter {
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

        $Images = Get-DockerImage @ProxyParameters

        $CompletionResults = [List[CompletionResult]]::new();
        $CompletedTags = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($Image in $Images) {
            $IsMatch = $Image.Name -like $wc -or $Image.id -like $wc
            if (-not $IsMatch) {
                continue
            }

            if ($parameterName -in 'ImageId', 'Id') {
                $CompletionText = $Image.Id
                $ListItemText = "$($Image.Id) ($($Image.Repository))"
            }
            # DockerImageCompleter is designed to complete from all images, so we don't
            # need to worry about filtering the tag down to tags for the specified image.
            elseif ($parameterName -eq 'Tag') {
                $CompletionText = $Image.Tag
                if (!$CompletedTags.Add($CompletionText)) {
                    continue
                }
                $ListItemText = $Image.Tag
            }
            elseif ($parameterName -in 'Repository', 'Name', 'ImageName', 'RepositoryName') {
                $CompletionText = $Image.Repository
                $ListItemText = "$($Image.Repository) ($($Image.Id))"
            }
            else {
                $CompletionText = $Image.FullName
                $ListItemText = "$($Image.FullName) ($($Image.Id))"
            }

            $SafeCompletionText = ConvertTo-CompletionText -InputObject $CompletionText -WordToComplete $wordToComplete

            $CompletionResults.Add(
                [CompletionResult]::new(
                    $SafeCompletionText,
                    $ListItemText,
                    'ParameterValue',
                    $CompletionText
                )
            )
        }

        return $CompletionResults
    }
}
