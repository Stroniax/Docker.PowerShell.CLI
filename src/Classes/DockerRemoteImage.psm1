using namespace System.Management.Automation

class DockerRemoteImage {
    hidden [psobject] $PSSourceValue

    [string] $Name

    [bool] $IsOfficial

    [bool] $IsAutomated

    [int] $StarCount

    [string] ToString() { return $this.Name }

    DockerRemoteImage([psobject] $deserializedJson) {
        $this.PSSourceValue = $deserializedJson
        $this.PSTypeNames.Insert(0, 'Docker.RemoteImage')
        $this.PSTypeNames.Insert(1, 'Docker.PowerShell.CLI.RemoteImage')

        foreach ($property in $deserializedJson.PSObject.Properties) {
            if ($this.PSObject.Properties[$property.Name]) { 
                $this.($property.Name) = $property.Value
            }
            else {
                $this.PSObject.Properties.Add($property.Copy())
            }
        }
    }
}
