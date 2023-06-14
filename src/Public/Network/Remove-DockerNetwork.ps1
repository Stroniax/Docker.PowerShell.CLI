using module ../../../Docker.PowerShell.CLI.psm1
using module ../../Classes/DockerNetworkCompleter.psm1
using namespace System.Management.Automation
using namespace System.Collections.Generic

function Remove-DockerNetwork {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        RemotingCapability = [RemotingCapability]::None,
        PositionalBinding = $false,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType([System.Management.Automation.Internal.AutomationNull])]
    [Alias('rdn')]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Name')]
        [ArgumentCompleter([DockerNetworkCompleter])]
        [string[]]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Id')]
        [ArgumentCompleter([DockerNetworkCompleter])]
        [string[]]
        $Id,

        [Parameter(ParameterSetName = 'Prune')]
        [Alias('Prune')]
        [switch]
        $UnusedNetworks,

        [Parameter()]
        [string]
        $Context
    )
    begin {
        $RemoveNetworks = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    }
    process {
        if ($Prune) {
            if (!$PSCmdlet.ShouldProcess(
                    'Removing unused docker networks.',
                    'Remove unused docker networks?',
                    'docker network prune'
                )) {
                return
            }

            Invoke-Docker network prune '--force' -Context $Context | Write-Debug
            return
        }

        $Networks = Get-DockerNetworkInternal -Name $Name -Id $Id -Context $Context -EscapeId

        foreach ($Network in $Networks) {
            if (!$PSCmdlet.ShouldProcess(
                    "Removing docker network '$($Network.Name)' ($($Network.Id)).",
                    "Remove docker network '$($Network.Name)' ($($Network.Id))?",
                    "docker network remove '$($Network.Id)'"
                )) {
                continue
            }

            $RemoveNetworks.Add($Network.Id)
        }
    }
    end {
        if ($RemoveNetworks.Count -eq 0) {
            return
        }
        $ArgumentList = @(
            'network'
            'remove'
            $RemoveNetworks
        )
        Invoke-Docker $ArgumentList -Context $Context | Write-Debug
    }
}