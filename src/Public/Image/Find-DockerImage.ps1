using namespace System.Management.Automation
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/BooleanArgumentCompleter.psm1
using module ../../Classes/EmptyStringArgumentCompleter.psm1
using module ../../Classes/NumericArgumentCompleter.psm1

function Find-DockerImage {
    [CmdletBinding(
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false
    )]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $Keyword,

        [Parameter()]
        [Alias('Automated')]
        [ArgumentCompleter([BooleanArgumentCompleter])]
        [Nullable[bool]]
        $IsAutomated,

        [Parameter()]
        [Alias('Official')]
        [ArgumentCompleter([BooleanArgumentCompleter])]
        [Nullable[bool]]
        $IsOfficial,

        [Parameter()]
        [Alias('Stars')]
        [ArgumentCompleter([NumericArgumentCompleter])]
        [int]
        $MinimumStars,

        [Parameter()]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('First', 'Take')]
        [ArgumentCompleter([NumericArgumentCompleter])]
        [int]
        $Limit = 100,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $ArgumentList = @(
            'search'
            '--no-trunc'
            "--limit=$Limit"
            '--format'
            '{{ json . }}'
            if ($IsAutomated.HasValue) { "--filter=is-automated=$IsAutomated" }
            if ($IsOfficial.HasValue) { "--filter=is-official=$IsOfficial" }
            if ($MinimumStars) { "--filter=stars=$MinimumStars" }
            $Keyword
        )
        $Count = 0
        Invoke-Docker $ArgumentList -Context $Context | ForEach-Object {
            $pso = $_ | ConvertFrom-Json
            $pso.PSTypeNames.Insert(0, 'Docker.RemoteImage')
            $pso

            if ((++$Count) -eq $Limit -and !($PSBoundParameters.ContainsKey('Limit'))) {
                Write-Warning "The number of results has reached the default limit of $Limit. There may be more results available. Use the -Limit parameter to increase the limit."
            }
        }
    }
}