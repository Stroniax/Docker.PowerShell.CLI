using namespace System.Collections.Generic
using namespace System.Management.Automation
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/DockerContext.psm1

function Get-DockerContext {
    [CmdletBinding(
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false
    )]
    [OutputType([DockerContext])]
    [Alias('gdcx')]
    param(
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('ContextName')]
        [ArgumentCompleter([DockerContextCompleter])]
        [string[]]
        $Name
    )
    process {
        $ReportNotMatched = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($i in $Name) {
            if (![WildcardPattern]::ContainsWildcardCharacters($i)) {
                [void]$ReportNotMatched.Add($i)
            }
        }

        Invoke-Docker context list --format '{{ json . }}' | ForEach-Object {
            [DockerContext]$pso = ConvertFrom-Json $_

            if (-not (Test-MultipleWildcard -WildcardPattern $Name -ActualValue $pso.Name)) {
                return
            }

            [void]$ReportNotMatched.Remove($pso.Name)
            $pso
        }

        foreach ($Unmatched in $ReportNotMatched) {
            Write-Error "No context found with name '$Unmatched'." -Category ObjectNotFound -ErrorId 'ContextNotFound' -TargetObject $Unmatched
        }
    }
}
