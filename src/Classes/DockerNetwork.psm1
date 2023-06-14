class DockerNetwork {

    hidden [psobject]$PSSourceValue

    [string]$Id

    [string]$Name

    [string]$Driver

    [string]$Scope

    [string[]]$Labels

    [DateTimeOffset]$CreatedAt

    [string] ToString() {
        return $this.Id
    }

    DockerNetwork([psobject]$deserializedJson) {
        $this.PSSourceValue = $deserializedJson
        $this.PSObject.TypeNames.Insert(0, 'Docker.Network')
        $this.PSObject.TypeNames.Insert(1, 'Docker.PowerShell.CLI.Network')

        foreach ($Property in $deserializedJson.PSObject.Properties) {
            if ($Property -is [psnoteproperty]) {
                # Handle special property values
                if ($Property.Name -eq 'Driver' -and $Property.Value -eq 'null') {
                    $this.Driver = $null
                    continue
                }
                if ($Property.Name -eq 'Labels') {
                    $this.Labels = $Property.Value -split ','
                    continue
                }
                if ($Property.Name -eq 'CreatedAt') {
                    $this.CreatedAt = [DateTimeOffset]::Parse($Property.Value.Substring(0, 33))
                    continue
                }

                # Handle normal property values
                if ($this.PSObject.Properties[$Property.Name]) {
                    $this.($Property.Name) = $Property.Value
                }
                else {
                    $Duplicate = $Property.Copy()
                    $asBool = $false
                    if ([bool]::TryParse($Duplicate.Value, [ref]$asBool)) {
                        $Duplicate.Value = $asBool
                    }
                    $this.PSObject.Properties.Add($Duplicate)
                }
            }
            else {
                Write-Warning "Unsupported property type '$($Property.GetType().Name)' for property '$($Property.Name)'. Contact the module author."
            }
        }
    }
}
