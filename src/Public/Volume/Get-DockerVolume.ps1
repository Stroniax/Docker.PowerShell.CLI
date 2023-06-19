using namespace System.Management.Automation
using namespace System.Collections.Generic
using module ../../Private/Test-MultipleWildcard.psm1
using module ../../Private/Invoke-Docker.psm1
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/DockerVolume.psm1
using module ../../Classes/LowerCaseTransformation.psm1

function Get-DockerVolume {
    [CmdletBinding(
        DefaultParameterSetName = 'Name',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false
    )]
    [OutputType([DockerVolume])]
    [Alias('gdv')]
    param(
        [Parameter(
            Position = 0,
            ParameterSetName = 'Name'
        )]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [LowerCaseTransformation()]
        [string[]]
        $Name,

        [Parameter()]
        [switch]
        $Dangling,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $ReportNotMatched = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

        $ArgumentList = [List[string]]::new()
        $ArgumentList.Add('volume')
        $ArgumentList.Add('list')
        $ArgumentList.Add('--format')
        $ArgumentList.Add('{{ json . }}')
        if ($Dangling) {
            $ArgumentList.Add('--filter')
            $ArgumentList.Add('dangling=true')
        }

        foreach ($n in $Name) {
            if (![WildcardPattern]::ContainsWildcardCharacters($n)) {
                [void]$ReportNotMatched.Add($n)
                $ArgumentList.Add('--filter')
                $ArgumentList.Add("name=$n")
            }
            else {
                # Add a filter of the longest non-wildcard substring
                # --filter uses OR matching for any substring, so we just want the shortest bit
                $filter = $n -split '[*?[\]]' | Sort-Object -Property Length -Descending | Select-Object -First 1
                if ($filter) {
                    $ArgumentList.Add('--filter')
                    $ArgumentList.Add("name=$filter")
                }
            }
        }

        Invoke-Docker -ArgumentList $ArgumentList | ConvertFrom-Json | ForEach-Object {
            $pso = [DockerVolume]::new($_)

            if (-not (Test-MultipleWildcard -WildcardPattern $Name -ActualValue $pso.Name)) {
                return
            }

            [void]$ReportNotMatched.Remove($pso.Name)

            $pso
        }

        foreach ($n in $ReportNotMatched) {
            $WriteError = @{
                Message      = "No such volume: '$n'."
                Exception    = [ItemNotFoundException]'The docker volume does not exist.'
                Category     = [ErrorCategory]::ObjectNotFound
                TargetObject = $n
                ErrorId      = 'VolumeNameNotFound'
            }
            Write-Error @WriteError
        }
    }
}