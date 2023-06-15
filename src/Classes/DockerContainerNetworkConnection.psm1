class DockerContainerNetworkConnection {
    hidden [PSObject]$PSSourceValue

    [string]$ContainerName

    [string]$ContainerId

    [string]$ImageName

    [string]$ImageId

    [string]$NetworkName

    [string]$NetworkId

    [string]$EndpointId

    [string]$MacAddress

    [ipaddress]$IPAddress

    [string[]]$Aliases

    [string] ToString() {
        return $this.EndpointId
    }

    DockerContainerNetworkConnection(
        [PSObject]$deserializedJson,
        [string]$ContainerId,
        [string]$ContainerName,
        [string]$ImageId,
        [string]$ImageName,
        [string]$NetworkName) {
        $this.PSSourceValue = $deserializedJson
        $this.ContainerId = $ContainerId
        $this.ContainerName = $ContainerName
        $this.ImageId = $ImageId
        $this.ImageName = $ImageName
        $this.NetworkName = $NetworkName
        $this.PSObject.TypeNames.Insert(0, 'Docker.ContainerNetworkConnection')
        $this.PSObject.TypeNames.Insert(1, 'Docker.PowerShell.CLI.ContainerNetworkConnection')

        foreach ($Property in $deserializedJson.PSObject.Properties) {
            if ($this.PSObject.Properties[$Property.Name]) {
                $this.$($Property.Name) = $Property.Value
            }
            else {
                $this.PSObject.Properties.Add($Property.Copy())
            }
        }
    }
}