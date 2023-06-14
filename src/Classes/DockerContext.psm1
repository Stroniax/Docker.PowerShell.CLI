class DockerContext {

    hidden [PSObject] $PSSourceValue

    [bool]$Current

    [string]$Name

    [string]$Description

    [string]$DockerEndpoint

    [string]$KubernetesEndpoint

    [string]$ContextType

    [string]$StackOrchestrator

    DockerContext([PSObject]$deserializedJson) {
        $this.PSSourceValue = $deserializedJson
        $this.PSTypeNames.Insert(0, 'Docker.Context')
        $this.PSTypeNames.Insert(1, 'Docker.PowerShell.CLI.Context')

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