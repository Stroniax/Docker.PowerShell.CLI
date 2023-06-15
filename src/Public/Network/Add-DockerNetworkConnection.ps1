using namespace System.Management.Automation
using namespace System.Collections.Generic
using module ../../Classes/DockerContainerNetworkConnection.psm1
using module ../../Classes/DockerContainerCompleter.psm1
using module ../../Classes/DockerNetworkCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1

function Add-DockerNetworkConnection {
    [CmdletBinding(
        DefaultParameterSetName = 'Name+Name',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [Alias('adnc')]
    [OutputType([DockerContainerNetworkConnection])]
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


        # Network-scoped alias for the container.
        [Parameter()]
        [string[]]
        $Alias,

        # IP address for the container on the network.
        [Parameter()]
        [ValidateScript({ $_.AddressFamily -in @('InterNetwork', 'InterNetworkv6' ) })]
        [IPAddress]
        $IPAddress,

        [Parameter()]
        [switch]
        $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    begin {
        $PassThruConnections = [Dictionary[string, HashSet[string]]]::new([StringComparer]::OrdinalIgnoreCase)
    }
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
                    foreach ($a in $Alias) { '--alias'; $a }
                    if ($IPAddress.AddressFamily -eq 'InterNetwork') { '--ip'; $IPAddress.ToString() }
                    if ($IPAddress.AddressFamily -eq 'InterNetworkv6') { '--ip6'; $IPAddress.ToString() }
                    $Network.Id
                    $Container.Id
                )

                if (!$PSCmdlet.ShouldProcess(
                        "Connecting docker container '$($Container.Name)' ($($Container.Id)) to network '$($Network.Name)' ($($Network.Id)).",
                        "Connect docker container '$($Container.Name)' ($($Container.Id)) to network '$($Network.Name)' ($($Network.Id))?",
                        "docker $ArgumentList"
                    )) {
                    continue
                }
                
                Invoke-Docker network connect $Network.Id $Container.Id -Context $Context

                if ($PassThru) {
                    if (!$PassThruConnections.ContainsKey($Container.Id)) {
                        $PassThruConnections[$Container.Id] = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
                    }
                    [void]$PassThruConnections[$Container.Id].Add($Network.Id)
                }
            }
        }
    }
    end {
        foreach ($Container in $PassThruConnections.Keys) {
            Get-DockerNetworkConnection -ContainerId $Container -NetworkId $PassThruConnections[$Container]
        }
    }
}