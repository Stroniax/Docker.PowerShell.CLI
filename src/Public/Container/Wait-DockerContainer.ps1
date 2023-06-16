using namespace System.Collections.Generic
using namespace System.Management.Automation
using module ../../Classes/DockerContainerCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1

function Wait-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false
    )]
    [OutputType([System.Management.Automation.Internal.AutomationNull])]
    [Alias('wdc')]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Name')]
        [SupportsWildcards()]
        [Alias('ContainerName')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Id')]
        [Alias('Container', 'ContainerId')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Id,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    begin {
        $ContainerIds = [HashSet[string]]::new()
    }
    process {
        $Containers = Get-DockerContainerInternal -Name $Name -Id $Id -EscapeId -Context $Context

        foreach ($Container in $Containers) {
            $ContainerIds.Add($Container.Id)
        }
    }
    end {
        if ($Containers.Count -eq 0) {
            Write-Verbose 'No containers to process.'
            return
        }
        $ArgumentList = @('wait'; $Containers.Id)
        Invoke-Docker -ArgumentList $ArgumentList -Context $Context | Write-Debug
    }
}
