using namespace System.Collections.Generic
using namespace System.Collections.ObjectModel

class DockerSystemStorage {
    hidden [psobject] $PSSourceValue

    DockerSystemStorage([psobject] $deserializedVerboseJson, [psobject[]] $deserializedSummaryJson) {
        $this.PSSourceValue = @{
            'Verbose' = $deserializedVerboseJson
            'Summary' = $deserializedSummaryJson
        }
        $this.PSTypeNames.Insert(0, 'Docker.SystemStorage')
        $this.PSTypeNames.Insert(1, 'Docker.PowerShell.CLI.SystemStorage')


        foreach ($property in $deserializedVerboseJson.PSObject.Properties) {
            $ThisProperty = $this.PSObject.Properties[$property.Name]
            if ($ThisProperty.IsSettable) {
                $this.$($property.Name) = $property.Value
            }
            elseif (!$thisProperty) {
                $this.PSObject.Properties.Add($property.Copy())
            }
        }

        $TempCategories = [Dictionary[string, DockerStorageCategory]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($summary in $deserializedSummaryJson) {
            $Category = switch ($Summary.Type) {
                'Local Volumes' {
                    [DockerVolumeStorageCategory]::new($summary, $deserializedVerboseJson.Volumes)
                }
                'Containers' {
                    [DockerContainerStorageCategory]::new($summary, $deserializedVerboseJson.Containers)
                }
                'Images' {
                    [DockerImageStorageCategory]::new($summary, $deserializedVerboseJson.Images)
                }
                'Build Cache' {
                    [DockerBuildCacheStorageCategory]::new($summary, $deserializedVerboseJson.BuildCache)
                }
                default {
                    [DockerStorageCategory]::new($summary)
                }
            }
            $TempCategories.Add($Summary.Type, $Category)
        }
        $this.Categories = $TempCategories
    }
    
    [ReadOnlyDictionary[string, DockerStorageCategory]] $Categories
}



class DockerStorageCategory {
    hidden [PSObject] $PSSourceValue

    DockerStorageCategory ([psobject]$deserializedJson) {
        $this.PSSourceValue = $deserializedJson
        $this.PSTypeNames.Insert(0, 'Docker.StorageCategory')
        $this.PSTypeNames.Insert(1, 'Docker.PowerShell.CLI.StorageCategory')

        foreach ($property in $deserializedJson.PSObject.Properties) {
            if ($Property.Name -eq 'Size') {
                $this.SizeLabel = $Property.Value
            }
            elseif ($Property.Name -eq 'Reclaimable') {
                $this.ReclaimableLabel = $Property.Value
            }
            elseif ($Property.Name -eq 'Active') {
                $this.ActiveCount = $Property.Value
            }
            elseif ($this.PSObject.Properties[$property.Name]) {
                $this.$($property.Name) = $property.Value
            }
            else {
                $this.PSObject.Properties.Add($property.Copy())
            }
        }
    }

    [string] $Type

    [int] $TotalCount

    # Size
    [string] $SizeLabel

    # Reclaimable
    # ReclaimablePercent
    [string] $ReclaimableLabel

    [int] $ActiveCount
}

class DockerContainerStorageCategory : DockerStorageCategory {
    [ReadOnlyCollection[DockerContainerStorage]] $Containers

    DockerContainerStorageCategory ([psobject]$deserializedJson, [DockerContainerStorage[]] $containers) : base($deserializedJson) {
        $this.PSTypeNames.Insert(0, 'Docker.ContainerStorageCategory')
        $this.PSTypeNames.Insert(1, 'Docker.PowerShell.CLI.ContainerStorageCategory')

        $this.Containers = $containers
    }

    [IEnumerator[DockerContainerStorage]] GetEnumerator() {
        return $this.Containers.GetEnumerator()
    }

    hidden [DockerContainerStorage] get_Item([string] $id) {
        return $this.Containers | Where-Object { $_.ID -eq $id }
    }
}

class DockerImageStorageCategory : DockerStorageCategory {
    [ReadOnlyCollection[DockerImageStorage]] $Images

    DockerImageStorageCategory ([psobject]$deserializedJson, [DockerImageStorage[]] $images) : base($deserializedJson) {
        $this.PSTypeNames.Insert(0, 'Docker.ImageStorageCategory')
        $this.PSTypeNames.Insert(1, 'Docker.PowerShell.CLI.ImageStorageCategory')

        $this.Images = $images
    }

    [IEnumerator[DockerImageStorage]] GetEnumerator() {
        return $this.Images.GetEnumerator()
    }
}

class DockerVolumeStorageCategory : DockerStorageCategory {
    [ReadOnlyCollection[DockerVolumeStorage]] $Volumes

    DockerVolumeStorageCategory ([psobject]$deserializedJson, [DockerVolumeStorage[]] $volumes) : base($deserializedJson) {
        $this.PSTypeNames.Insert(0, 'Docker.VolumeStorageCategory')
        $this.PSTypeNames.Insert(1, 'Docker.PowerShell.CLI.VolumeStorageCategory')

        $this.Volumes = $volumes
    }

    [IEnumerator[DockerVolumeStorage]] GetEnumerator() {
        return $this.Volumes.GetEnumerator()
    }
}

class DockerBuildCacheStorageCategory : DockerStorageCategory {
    [ReadOnlyCollection[DockerBuildCacheStorage]] $BuildCache

    DockerBuildCacheStorageCategory ([psobject]$deserializedJson, [DockerBuildCacheStorage[]] $buildCache) : base($deserializedJson) {
        $this.PSTypeNames.Insert(0, 'Docker.BuildCacheStorageCategory')
        $this.PSTypeNames.Insert(1, 'Docker.PowerShell.CLI.BuildCacheStorageCategory')

        $this.BuildCache = $buildCache
    }

    [IEnumerator[DockerBuildCacheStorage]] GetEnumerator() {
        return $this.BuildCache.GetEnumerator()
    }
}

class DockerContainerStorage {
    hidden [psobject] $PSSourceValue

    DockerContainerStorage ([psobject]$deserializedJson) {
        $this.PSSourceValue = $deserializedJson
        $this.PSTypeNames.Insert(0, 'Docker.ContainerStorage')
        $this.PSTypeNames.Insert(1, 'Docker.PowerShell.CLI.ContainerStorage')

        foreach ($property in $deserializedJson.PSObject.Properties) {
            if ($property.Name -eq 'Size') {
                $this.SizeLabel = $property.Value
            }
            elseif ($Property.Name -eq 'LocalVolumes') {
                $this.LocalVolumeCount = $property.Value
            }
            elseif ($property.Name -eq 'CreatedAt') {
                $this.CreatedAt = [datetimeoffset][string]$property.value.split(' ')[0..2]
            }
            elseif ($property.name -eq 'labels') {
                $this.labels = $property.value -split ','
            }
            elseif ($property.Name -eq 'Mounts') {
                $this.Mounts = $property.Value -split ','
            }
            elseif ($property.Name -eq 'Names') {
                $this.Names = $property.Value -split ','
            }
            elseif ($property.Name -eq 'Networks') {
                $this.Networks = $property.Value -split ','
            }
            elseif ($property.Name -eq 'Ports') {
                $this.Ports = $property.Value -split ','
            }
            elseif ($this.PSObject.Properties[$property.Name]) {
                $this.$($property.Name) = $property.Value
            }
            else {
                $this.PSObject.Properties.Add($property.Copy())
            }
        }
    }

    [string] $Command

    [DateTimeOffset] $CreatedAt

    [string] $Id

    [string] $Image

    [string[]] $Labels

    [int] $LocalVolumeCount

    [string[]] $Mounts

    [string[]] $Names

    [string[]] $Networks

    [string[]] $Ports

    # Size
    [string] $SizeLabel

    [string] $Status
}

class DockerImageStorage {
    hidden [psobject] $PSSourceValue

    DockerImageStorage ([psobject] $deserializedJson) {
        $this.PSSourceValue = $deserializedJson
        $this.PSTypeNames.Insert(0, 'Docker.ImageStorage')
        $this.PSTypeNames.Insert(1, 'Docker.PowerShell.CLI.ImageStorage')

        foreach ($property in $deserializedJson.PSObject.Properties) {
            if ($property.Name -eq 'Size') {
                $this.SizeLabel = $property.Value
            }
            elseif ($Property.Name -eq 'SharedSize') {
                $this.SharedSizeLabel = $property.Value
            }
            elseif ($Property.Name -eq 'UniqueSize') {
                $this.UniqueSizeLabel = $property.Value
            }
            elseif ($Property.Name -eq 'VirtualSize') {
                $this.VirtualSizeLabel = $property.Value
            }
            elseif ($property.Name -eq 'Containers') {
                $this.ContainerCount = $property.Value
            }
            elseif ($property.Name -eq 'CreatedAt') {
                $this.CreatedAt = [datetimeoffset][string]$property.value.split(' ')[0..2]
            }
            elseif ($this.PSObject.Properties[$property.Name]) {
                $this.$($property.Name) = $property.Value
            }
            else {
                $this.PSObject.Properties.Add($property.Copy())
            }
        }
    }

    # From 'Containers'
    [int] $ContainerCount

    [DateTimeOffset] $CreatedAt

    [string] $Digest

    [string] $Id

    [string] $Repository

    # SharedSize
    [string] $SharedSizeLabel

    # Size
    [string] $SizeLabel

    [string] $Tag

    # UniqueSize
    [string] $UniqueSizeLabel

    # VirtualSize
    [string] $VirtualSizeLabel
}

class DockerVolumeStorage {
    hidden [psobject] $PSSourceValue

    DockerVolumeStorage([psobject]$deserializedJson) {
        $this.PSSourceValue = $deserializedJson
        $this.PSTypeNames.Insert(0, 'Docker.VolumeStorage')
        $this.PSTypeNames.Insert(1, 'Docker.PowerShell.CLI.VolumeStorage')

        foreach ($property in $deserializedJson.PSObject.Properties) {
            if ($property.Name -eq 'Size') {
                $this.SizeLabel = $property.Value
            }
            elseif ($property.Name -eq 'Links') {
                $this.LinkCount = $property.Value
            }
            elseif ($property.Name -eq 'Labels') {
                $this.Labels = $property.Value -split ','
            }
            elseif ($this.PSObject.Properties[$property.Name]) {
                $this.$($property.Name) = $property.Value
            }
            else {
                $this.PSObject.Properties.Add($property.Copy())
            }
        }
    }

    [string] $Driver

    [string[]] $Labels

    [int] $LinkCount

    [string] $Mountpoint

    [string] $Name

    [string] $Scope

    # Size
    [string] $SizeLabel
}

class DockerBuildCacheStorage {
    hidden [psobject] $PSSourceValue

    DockerBuildCacheStorage ([psobject]$deserializedJson) {
        $this.PSSourceValue = $deserializedJson
        $this.PSTypeNames.Insert(0, 'Docker.BuildCacheStorage')
        $this.PSTypeNames.Insert(1, 'Docker.PowerShell.CLI.BuildCacheStorage')

        foreach ($property in $deserializedJson.PSObject.Properties) {
            if ($property.Name -eq 'Size') {
                $this.SizeLabel = $property.Value
            }
            elseif ($property.Name -eq 'CreatedAt') {
                $this.CreatedAt = [DateTimeOffset][string]$property.Value.Split(' ')[0..2]
            }
            elseif ($property.Name -eq 'LastUsedat') {
                $this.LastUsedAt = [DateTimeOffset][string]$property.Value.Split(' ')[0..2]
            }
            elseif ($this.PSObject.Properties[$property.Name]) {
                $this.$($property.Name) = $property.Value
            }
            else {
                $this.PSObject.Properties.Add($property.Copy())
            }
        }
    }

    [string] $CacheType

    [DateTimeOffset] $CreatedAt

    [string] $Description

    [string] $Id

    [bool] $InUse

    [DateTimeOffset] $LastUsedAt

    [string] $Parent

    [bool] $Shared

    # Size
    [string] $SizeLabel

    [int] $UsageCount
}

