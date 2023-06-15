using namespace System.Management.Automation
using module ../../Classes/DockerContainerCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/DockerBinArgumentCompleter.psm1

#TODO: Does not reliably enter a prompt in the container
# Depends on the container having /bin/ash
function Enter-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false
    )]
    [OutputType([System.Management.Automation.Internal.AutomationNull])]
    [Alias('etdc')]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Name')]
        [SupportsWildcards()]
        [Alias('ContainerName')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Id')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [Alias('Container', 'ContainerId')]
        [string]
        $Id,

        [Parameter(Mandatory, Position = 1)]
        [ArgumentCompleter([DockerBinArgumentCompleter])]
        [string[]]
        $Command,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $Container = Get-DockerContainerSingle -Name $Name -Id $Id -Context $Context
        if (!$?) { return }

        if ($Container.State -ne 'running') {
            Write-Error "Cannot enter container $($Container.Id) ($($Container.Names)) because it is not running."
            return
        }

        $ArgumentList = @(
            'exec'
            '-it'
            $Container.Id
            $Command
        )

        Invoke-Docker -ArgumentList $ArgumentList -Context $Context
    }
}
