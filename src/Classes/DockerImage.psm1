class DockerImage {

    hidden [PSObject]$PSSourceObject

    [string]$Id

    [string]$Repository

    [string[]]$Containers

    [DateTimeOffset]$CreatedAt

    [string[]]$Labels

    [string]$Digest

    [string]$Tag

    [string[]]$Mounts

    DockerImage([PSObject]$deserializedJson) {
        $this.PSSourceObject = $deserializedJson
        $this.PSTypeNames.Insert(0, 'Docker.Image')
        $this.PSTypeNames.Insert(1, 'Docker.PowerShell.CLI.Image')

        foreach ($Property in $deserializedJson.PSObject.Properties) {
            if ($Property.Name -eq 'Containers') {
                if ($Property.Value -eq 'N/A') {
                    $this.Containers = @()
                }
                else {
                    $this.Containers = $Property.Value -split ','
                }
            }
            elseif ($Property.Name -eq 'CreatedAt') {
                $this.CreatedAt = [DateTimeOffset][string]$Property.Value.Split(' ')[0..2]
            }
            elseif ($Property.Name -eq 'Labels') {
                $this.Labels = $Property.Value -split ','
            }
            elseif ($Property.Name -eq 'Mounts') {
                $this.Mounts = $Property.Value -split ','
            }
            elseif ($this.PSObject.Properties[$Property.Name]) {
                $this.($Property.Name) = $Property.Value
            }
            else {
                $this.PSObject.Properties.Add($Property.Copy())
            }
        }
    }
}