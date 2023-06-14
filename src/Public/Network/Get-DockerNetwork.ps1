using module ../../Classes/DockerNetworkCompleter.psm1
using module ../../Classes/DockerNetwork.psm1
using module ../../../Docker.PowerShell.CLI.psm1
using namespace System.Management.Automation
using namespace System.Collections.Generic

function Get-DockerNetwork {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        RemotingCapability = [RemotingCapability]::None,
        PositionalBinding = $false
    )]
    [OutputType([DockerNetwork])]
    [Alias('gdn')]
    param(
        [Parameter(Position = 0, ParameterSetName = 'Name')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerNetworkCompleter])]
        [string[]]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Id')]
        [SupportsWildcards()]
        [Alias('NetworkId')]
        [ArgumentCompleter([DockerNetworkCompleter])]
        [string[]]
        $Id,

        [Parameter()]
        [ArgumentCompleter([DockerNetworkCompleter])]
        [string[]]
        $Driver,

        [Parameter()]
        [ArgumentCompleter([DockerNetworkCompleter])]
        [string[]]
        $Scope,

        [Parameter()]
        [ValidateSet('custom', 'builtin')]
        [string[]]
        $Type,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $ReportNotMatched = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

        foreach ($i in $Id) {
            if (![WildcardPattern]::ContainsWildcardCharacters($i)) {
                [void]$ReportNotMatched.Add($i)
            }
        }
        foreach ($n in $Name) {
            if (![WildcardPattern]::ContainsWildcardCharacters($n)) {
                [void]$ReportNotMatched.Add($n)
            }
        }

        $ArgumentList = @(
            'network'
            'list'
            '--format'
            '{{ json . }}'
            '--no-trunc'
            foreach ($i in $Id | ConvertTo-DockerWildcard) {
                '--filter'
                "id=$i"
            }
            foreach ($n in $Name | ConvertTo-DockerWildcard) {
                '--filter'
                "name=$n"
            }
            foreach ($d in $Driver) {
                '--filter'
                "driver=$d"
            }
            foreach ($s in $Scope) {
                '--filter'
                "scope=$s"
            }
            foreach ($t in $Type) {
                '--filter'
                "type=$t"
            }
        )

        Invoke-Docker $ArgumentList -Context $Context | ConvertFrom-Json | ForEach-Object {
            $Network = [DockerNetwork]::new($_)
            if (-not (Test-MultipleWildcard -WildcardPattern $Name -ActualValue $Network.Name)) {
                return
            }
            if (-not (Test-MultipleWildcard -WildcardPattern $Id -ActualValue $Network.Id)) {
                return
            }

            [void]$ReportNotMatched.Remove($Network.Id)
            [void]$ReportNotMatched.Remove($Network.Name)

            $Network
        }

        foreach ($NotMatched in $ReportNotMatched) {
            $Exception = [ItemNotFoundException]::new(
                'The docker network was not found.'
            )
            $ErrorRecord = [ErrorRecord]::new(
                $Exception,
                'NetworkNotFound',
                [ErrorCategory]::ObjectNotFound,
                $NotMatched
            )
            $ErrorRecord.ErrorDetails = "No network found with the $($PSCmdlet.ParameterSetName) '$NotMatched'."
            Write-Error -ErrorRecord $ErrorRecord
        }
    }
}