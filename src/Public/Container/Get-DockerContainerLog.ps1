using namespace System.Management.Automation
using module ../../Classes/DockerContainerCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1

function Get-DockerContainerLog {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        PositionalBinding = $false,
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Name')]
        [SupportsWildcards()]
        [Alias('ContainerName')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Id')]
        [Alias('Container', 'ContainerId')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string]
        $Id,

        [Parameter()]
        [DateTime]
        $Since,

        [Parameter()]
        [DateTime]
        $Until,

        [Parameter()]
        [Alias('Tail')]
        [int]
        $Last,

        [Parameter()]
        [switch]
        $Follow,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $Container = Get-DockerContainerSingle -Name $Name -Id $Id -Context $Context
        if (!$?) { return }

        $ArgumentList = @(
            'container'
            'logs'
            $Container.Id
            '--timestamps'
            '--details'
        )

        if ($Follow) {
            $ArgumentList += '--follow'
        }

        if ($Last) {
            $ArgumentList += '--tail'
            $ArgumentList += $Last
        }

        if ($Since) {
            $ArgumentList += '--since'
            $ArgumentList += $Since.ToString('yyyy-MM-ddTHH:mm:ss')
        }

        if ($Until) {
            $ArgumentList += '--until'
            $ArgumentList += $Until.ToString('yyyy-MM-ddTHH:mm:ss')
        }

        Write-Debug "$ArgumentList"
        Invoke-Docker $ArgumentList -Context $Context
    }
}
