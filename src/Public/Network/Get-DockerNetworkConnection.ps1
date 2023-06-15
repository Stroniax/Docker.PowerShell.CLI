using namespace System.Management.Automation
using namespace System.Collections.Generic
using module ../../Classes/DockerContainerNetworkConnection.psm1
using module ../../Classes/DockerContainerCompleter.psm1
using module ../../Classes/DockerNetworkCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/EmptyStringArgumentCompleter.psm1

function Get-DockerNetworkConnection {
    [CmdletBinding(
        DefaultParameterSetName = 'Name',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false
    )]
    [OutputType([DockerContainerNetworkConnection])]
    [Alias('gdnc')]
    param(
        [Parameter(Position = 0, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerNetworkCompleter])]
        [string[]]
        $NetworkName,

        [Parameter(Position = 1, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $ContainerName,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Parent')]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $ContainerId,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Parent')]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerNetworkCompleter])]
        [string[]]
        $NetworkId,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        $Context
    )
    begin {
        $EndpointIds = [HashSet[string]]::new()
    }
    process {
        $Containers = Get-DockerContainerInternal -Context $Context -Id $ContainerId -Name $ContainerName -ErrorAction SilentlyContinue -ErrorVariable DockerContainerErrors
        
        foreach ($e in $DockerContainerErrors) {
            $exn = [ItemNotFoundException]::new(
                "No docker network connection found for container '$($e.TargetObject)' because the container does not exist.",
                $exn.Exception
            )
            $er = [ErrorRecord]::new(
                $exn,
                'NetworkConnectionNotFound.Container',
                [ErrorCategory]::ObjectNotFound,
                $e.TargetObject
            )
            $PSCmdlet.WriteError($er)
        }

        if ($Containers.Count -eq 0) {
            return
        }

        $NotMatchedNetworkName = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $NetworkName.Where({ ![WildcardPattern]::ContainsWildcardCharacters($_) }).ForEach({ [void]$NotMatchedNetworkName.Add($_) })
        $NotMatchedEndpointId = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $EndpointId.Where({ ![WildcardPattern]::ContainsWildcardCharacters($_) }).ForEach({ [void]$NotMatchedEndpointId.Add($_) })
        $NotMatchedNetworkId = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $NetworkId.Where({ ![WildcardPattern]::ContainsWildcardCharacters($_) }).ForEach({ [void]$NotMatchedNetworkId.Add($_) })

        Invoke-Docker container inspect $Containers.Id `
        | ConvertFrom-Json `
        | ForEach-Object {
            $ConnectionContainerId = $_.Id
            $ConnectionContainerName = $_.Name
            $ConnectionImageId = $_.Image
            $ConnectionImageName = $_.Config.Image
            foreach ($Property in $_.NetworkSettings.Networks.PSObject.Properties) {
                $ConnectionNetworkName = $Property.Name
                $Connection = [DockerContainerNetworkConnection]::new(
                    $Property.Value,
                    $ConnectionContainerId,
                    ($ConnectionContainerName -replace '^/', ''),
                    $ConnectionImageId,
                    $ConnectionImageName,
                    $ConnectionNetworkName
                )
                $Connection.PSObject.Properties.Add([psnoteproperty]::new('PSDockerContext', $Context))

                if ($EndpointIds.Add($Connection.EndpointId) -and
                    (Test-MultipleWildcard -WildcardPattern $EndpointId -ActualValue $Connection.EndpointId) -and
                    (Test-MultipleWildcard -WildcardPattern $NetworkName -ActualValue $Connection.NetworkName) -and
                    (Test-MultipleWildcard -WildcardPattern $NetworkId -ActualValue $Connection.NetworkId)) {

                    [void]$NotMatchedEndpointId.Remove($Connection.EndpointId)
                    [void]$NotMatchedNetworkName.Remove($Connection.NetworkName)
                    [void]$NotMatchedNetworkId.Remove($Connection.NetworkId)
                        
                    $Connection
                }
            }
        }

        foreach ($i in $NotMatchedEndpointId) {
            Write-Error -Exception ([ItemNotFoundException]"No docker network connection found with with endpoint '$i'.") -Category ObjectNotFound -ErrorId 'NetworkConnectionNotFound.EndpointId' -TargetObject $i
        }
        foreach ($i in $NotMatchedNetworkName) {
            Write-Error -Exception ([ItemNotFoundException]"No docker network connection found for network '$i'.") -Category ObjectNotFound -ErrorId 'NetworkConnectionNotFound.NetworkName' -TargetObject $i
        }
        foreach ($i in $NotMatchedNetworkId) {
            Write-Error -Exception ([ItemNotFoundException]"No docker network connection found for network '$i'.") -Category ObjectNotFound -ErrorId 'NetworkConnectionNotFound.NetworkId' -TargetObject $i
        }
    }
}
