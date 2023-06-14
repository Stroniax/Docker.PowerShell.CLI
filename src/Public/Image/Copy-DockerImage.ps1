using namespace System.Management.Automation
using module ../../Classes/DockerImageCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1

# Creates a duplicate image with a new name based on a source docker image
# This uses the `docker image tag` command.
function Copy-DockerImage {
    [CmdletBinding(
        SupportsShouldProcess,
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        ConfirmImpact = [ConfirmImpact]::Low,
        PositionalBinding = $false
    )]
    [OutputType('Docker.Image')]
    [Alias('cpdi')]
    param(
        # Full name of the source image
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'FullName')]
        [SupportsWildcards()]
        [Alias('Reference', 'SourceReference', 'SourceFullName', 'SourceImage', 'Source')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $FullName,

        # FullName for the destination image (the copy to be created)
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Alias('TargetImage', 'TargetName', 'DestinationFullName', 'DestinationImage', 'DestinationReference', 'TargetReference')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $DestinationName,

        # Id of the source image
        [Parameter(Mandatory, ParameterSetName = 'Id')]
        [Alias('ImageId')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $Id,

        [Parameter()]
        [switch]
        $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    dynamicparam {
        [string]$DestinationName = $PSBoundParameters['DestinationName'];

        if ($DestinationName.Contains(':')) {
            return $null
        }

        $DynamicParameters = [RuntimeDefinedParameterDictionary]::new()
        $DynamicParameters.Add('DestinationTag', [RuntimeDefinedParameter]::new(
                'DestinationTag',
                [string],
                [ObjectModel.Collection[Attribute]]@(
                    [ParameterAttribute]@{
                        Mandatory                       = $true
                        Position                        = 2
                        ValueFromPipelineByPropertyName = $true
                    },
                    [AliasAttribute]::new('Tag')
                )
            ))
        return $DynamicParameters
    }
    process {
        $Images = Get-DockerImageInternal -Id $Id -FullName $FullName -EscapeId -Context $Context | Sort-Object -Property Id -Unique

        # Handle no images
        if ($Images.Count -eq 0) {
            Write-Verbose 'No images to process.'
            return
        }

        # Handle ambiguous images
        if ($Images.Count -gt 1) {
            $Message = if ($Id) { "Id '$Id'" } else { "Name '$FullName'" }
            $TargetObject = if ($Id) { $Id } else { $FullName }
            Write-Error "More than one image found for $Message." -Category InvalidArgument -ErrorId 'AmbiguousImage' -TargetObject $TargetObject
            return
        }

        # Handle dynamic parameter in case someone wants to provide destination name and tag as separate arguments
        if ($PSBoundParameters['DestinationTag']) {
            $DestinationName = "${DestinationName}:$($PSBoundParameters['DestinationTag'])"
        }

        # ShouldProcess?
        $ResolvedImage = $Images[0]
        if (!$PSCmdlet.ShouldProcess(
                "Creating new tag '$DestinationName' for image '$($ResolvedImage.FullName)' ($($ResolvedImage.Id)).",
                "Create new tag '$DestinationName' for image '$($ResolvedImage.FullName)' ($($ResolvedImage.Id))?",
                "docker image tag '$($ResolvedImage.Id)' '$DestinationName'"
            )) {
            return
        }

        # execute
        $ArgumentList = @(
            'image'
            'tag'
            $ResolvedImage.Id
            $DestinationName
        )

        Invoke-Docker $ArgumentList -Context $Context

        # PassThru
        if ($? -and $PassThru) {
            Get-DockerImage -FullName $DestinationName -Context $Context
        }
    }
}
