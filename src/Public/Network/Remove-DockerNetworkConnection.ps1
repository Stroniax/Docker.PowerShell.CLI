using namespace System.Management.Automation
using namespace System.Collections.Generic
using module ../../Classes/DockerContainerNetworkConnection.psm1
using module ../../Classes/DockerContainerCompleter.psm1
using module ../../Classes/DockerNetworkCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1

function Remove-DockerNetworkConnection {
    [CmdletBinding(
        DefaultParameterSetName = 'Name+Name',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [Alias('rdnc')]
    [OutputType([System.Management.Automation.Internal.AutomationNull])]
    param(
        [Parameter(
            Mandatory,
            Position = 0,
            ParameterSetName = 'Name+Id'
        )]
        [Parameter(
            Mandatory,
            Position = 0,
            ParameterSetName = 'Name+Name'
        )]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerNetworkCompleter])]
        [string[]]
        $NetworkName,

        [Parameter(
            Mandatory,
            Position = 0,
            ParameterSetName = 'Id+Name'
        )]
        [Parameter(
            Mandatory,
            Position = 1,
            ParameterSetName = 'Name+Name'
        )]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $ContainerName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Id+Id'
        )]
        [ArgumentCompleter([DockerNetworkCompleter])]
        [string[]]
        $NetworkId,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Name+Id'
        )]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Id+Id'
        )]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $ContainerId,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $Networks = Get-DockerNetworkInternal -Name $NetworkName -Id $NetworkId -EscapeId
        $Containers = Get-DockerContainerInternal -Name $ContainerName -Id $ContainerId -EscapeId

        if ($Networks.Count -eq 0) {
            Write-Verbose 'No networks to process.'
            return
        }
        if ($Containers.Count -eq 0) {
            Write-Verbose 'No containers to process.'
            return
        }

        $RequiresSingle = $Alias -or $IPAddress
        if ($RequiresSingle -and $Containers.Count -gt 1) {
            throw [InvalidOperationException]::new('Cannot specify multiple containers when using -Alias or -IPAddress.')
        }

        foreach ($Network in $Networks) {
            foreach ($Container in $Containers) {

                $ArgumentList = @(
                    'network'
                    'connect'
                    $Network.Id
                    $Container.Id
                )

                if (!$PSCmdlet.ShouldProcess(
                        "Disconnecting docker container '$($Container.Name)' ($($Container.Id)) from network '$($Network.Name)' ($($Network.Id)).",
                        "Disconnect docker container '$($Container.Name)' ($($Container.Id)) from network '$($Network.Name)' ($($Network.Id))?",
                        "docker $ArgumentList"
                    )) {
                    continue
                }
                
                Invoke-Docker network disconnect $Network.Id $Container.Id -Context $Context
            }
        }
    }
}