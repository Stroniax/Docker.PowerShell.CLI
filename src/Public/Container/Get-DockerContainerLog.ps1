using namespace System.Management.Automation
using module ../../Classes/DockerContainerCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/NumericArgumentCompleter.psm1
using module ../../Classes/DateTimeArgumentCompleter.psm1

function Get-DockerContainerLog {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        PositionalBinding = $false,
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    [OutputType([string])]
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
        [ArgumentCompleter([DateTimeArgumentCompleter])]
        [DateTime]
        $Since,

        [Parameter()]
        [ArgumentCompleter([DateTimeArgumentCompleter])]
        [DateTime]
        $Until,

        [Parameter()]
        [Alias('Tail')]
        [ArgumentCompleter([NumericArgumentCompleter])]
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
        Invoke-Docker -ArgumentList $ArgumentList -Context $Context
    }
}
