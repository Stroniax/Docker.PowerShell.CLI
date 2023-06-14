# Helper function to get a container by name or id depending on which
# parameters were passed to the origin function. If the id parameter
# is passed, it will be escaped so that it does not support wildcard
# patterns. This function will throw an error if more than one container
# is found or if no containers are found and the allow none switch is
# not specified.
function Get-DockerContainerSingle {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [string]
        $Context,

        [Parameter()]
        [switch]
        $AllowNone
    )
    process {
        $Containers = Get-DockerContainerInternal -Name $Name -Id $Id -Context $Context -EscapeId

        $Message = if ($Name) { "name '$Name'" } else { "id '$Id'" }
        $TargetObject = if ($Name) { $Name } else { $Id }

        if ($Containers.Count -gt 1) {
            Write-Error "More than one container found for $Message." -Category InvalidArgument -ErrorId 'AmbiguousContainer' -TargetObject $TargetObject
        }
        if ($Containers.Count -eq 0 -and !$AllowNone) {
            Write-Error "No container found for $Message." -Category ObjectNotFound -ErrorId 'ContainerNotFound' -TargetObject $TargetObject
        }

        $Containers
    }
}
