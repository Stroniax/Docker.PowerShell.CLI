using namespace System.Management.Automation
using module ../../Classes/DockerContainerCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/DockerContainer.psm1

function Rename-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType([DockerContainer])]
    [Alias('rndc')]
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
        [string]
        $NewName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context,

        [Parameter()]
        [switch]
        $PassThru
    )
    process {
        $Container = Get-DockerContainerSingle -Name $Name -Id $Id -Context $Context
        if (!$?) { return }

        if ($PSCmdlet.ShouldProcess(
                "Renaming docker container '$($Container.Id)' from '$($Container.Names)' to $($NewName).",
                "Rename docker container '$($Container.Id)' from '$($Container.Names)' to $($NewName)?",
                "docker $ArgumentList")) {
            Invoke-Docker rename $Container.Id $NewName -Context $Context
            if ($PassThru) {
                Get-DockerContainerSingle -Name $NewName -Context $Context
            }
        }
    }
}
