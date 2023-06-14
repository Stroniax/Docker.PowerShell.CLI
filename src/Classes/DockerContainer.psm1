class DockerContainer {

    hidden [PSObject]$PSSourceValue

    [string]$Id

    [string[]]$Names

    [string[]]$Labels

    [string]$Image

    [string]$Command

    [string]$Status

    [string[]]$Ports

    [DateTimeOffset]$CreatedAt

    [string] ToString() {
        return $this.Id
    }

    DockerContainer([psobject]$deserializedJson) {
        $this.PSSourceValue = $deserializedJson
        $this.PSObject.TypeNames.Insert(0, 'Docker.Container')
        $this.PSObject.TypeNames.Insert(1, 'Docker.PowerShell.CLI.Container')

        foreach ($Property in $deserializedJson.PSObject.Properties) {
            if ($Property.Name -eq 'Names') {
                $this.Names = $Property.Value -split ','
            }
            elseif ($Property.Name -eq 'Labels') {
                $this.Labels = $Property.Value -split ','
            }
            elseif ($Property.Name -eq 'Ports') {
                $this.Ports = $Property.Value -split ','
            }
            elseif ($Property.Name -eq 'CreatedAt') {
                $this.CreatedAt = [DateTimeOffset][string]$Property.Value.Split(' ')[0..2]
            }
            elseif ($this.PSObject.Properties[$Property.Name]) {
                $this.$($Property.Name) = $Property.Value
            }
            else {
                $this.PSObject.Properties.Add($Property.Copy())
            }
        }
    }
}