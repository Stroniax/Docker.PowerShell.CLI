using namespace System.Management.Automation
using module ../../Classes/DockerImageCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1

function Export-DockerImage {
    [CmdletBinding(
        DefaultParameterSetName = 'FullName',
        SupportsShouldProcess,
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        ConfirmImpact = [ConfirmImpact]::Low,
        PositionalBinding = $false
    )]
    [OutputType('System.IO.FileInfo')]
    [Alias('epdi')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName, ParameterSetName = 'FullName')]
        [SupportsWildcards()]
        [Alias('Reference')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $FullName,

        [Parameter(Mandatory, ParameterSetName = 'Id')]
        [Alias('ImageId')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $Id,

        [Parameter(Mandatory, Position = 1)]
        [Alias('Path')]
        [string]
        $Destination,

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [switch]
        $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $Images = Get-DockerImageInternal -Id $Id -FullName $FullName -EscapeId | Sort-Object -Property Id -Unique

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

        # Resolve destination path
        $OutputPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Destination)
        if (!$?) {
            return
        }
        if (Test-Path $OutputPath -PathType Container) {
            Write-Error "Destination path '$Destination' is a directory." -Category InvalidArgument -ErrorId 'DestinationIsDirectory' -TargetObject $OutputPath
            return
        }
        if (!$Force -and (Test-Path $OutputPath -PathType Leaf)) {
            Write-Error "Destination path '$Destination' already exists." -Category InvalidArgument -ErrorId 'DestinationExists' -TargetObject $OutputPath
            return
        }

        # ShouldProcess?
        $ResolvedImage = $Images[0]
        if (!$PSCmdlet.ShouldProcess(
                "Exporting image '$($ResolvedImage.FullName)' ($($ResolvedImage.Id)) to '$Destination'.",
                "Export image '$($ResolvedImage.FullName)' ($($ResolvedImage.Id)) to '$Destination'?",
                "docker image save --output '$Outputpath' '$($ResolvedImage.Id)'"
            )) {
            return
        }

        Invoke-Docker image save --output $OutputPath $ResolvedImage.Id -Context $Context

        if ($PassThru) {
            Get-Item $OutputPath
        }
    }
}