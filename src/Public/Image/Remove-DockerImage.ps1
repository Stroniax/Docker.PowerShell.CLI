using namespace System.Collections.Generic
using namespace System.Management.Automation
using module ../../Classes/DockerImageCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1

function Remove-DockerImage {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType([System.Management.Automation.Internal.AutomationNull])]
    [Alias('rdi')]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'FullName', ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [Alias('Reference')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string[]]
        $FullName,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [Alias('RepositoryName', 'ImageName')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $Tag,

        [Parameter(Mandatory, ParameterSetName = 'Id')]
        [Alias('ImageId')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string[]]
        $Id,

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    begin {
        $ArgumentList = [List[string]]::new()
        $ArgumentList.Add('image')
        $ArgumentList.Add('remove')
        if ($Force) {
            $ArgumentList.Add('--force')
        }
    }
    process {
        $Images = Get-DockerImageInternal -Name $Name -Tag $Tag -Id $Id -FullName $FullName -Context $Context -EscapeId

        if ($Images.Count -eq 0) {
            Write-Verbose 'No images to process.'
        }

        foreach ($Image in $Images) {
            if ($PSCmdlet.ShouldProcess(
                    "Removing docker image $($Image.FullName) ($($Image.Id)).",
                    "Remove docker image $($Image.FullName) ($($Image.Id))?",
                    "docker image remove $($Image.FullName)"
                )) {
                $ArgumentList.Add($Image.FullName)
            }
        }
    }
    end {
        if ($ArgumentList.Count -eq 2) {
            # no images
            return
        }
        Invoke-Docker -ArgumentList $ArgumentList -Context $Context | Write-Debug
    }
}