class DockerVolume {

    hidden [psobject]$PSSourceValue

    [string]$Availability

    [string]$Driver

    [string]$Group

    [string[]]$Labels

    [string[]]$Links

    [string]$Mountpoint

    [string]$Name

    [string]$Scope

    [string]$Size

    [string]$Status

    [string] ToString() {
        return $this.Name
    }

    DockerVolume([psobject]$deserializedJson) {
        $this.PSSourceValue = $deserializedJson
        $this.PSTypeNames.Insert(0, 'Docker.Volume')
        $this.PSTypeNames.Insert(0, 'Docker.PowerShell.CLI.Volume')

        foreach ($property in $deserializedJson.PSObject.Properties) {
            if ($property.Name -eq 'Labels') {
                $this.Labels = $property.Value -split ','
            }
            elseif ($property.Name -eq 'Links') {
                $this.Links = $property.Value -split ','
            }
            else {
                $this.$($property.Name) = $property.Value
            }
        }
    }
}