using namespace System.Collections.Generic
using namespace System.Management.Automation
using module ../../Classes/DockerImageCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/DockerBuildAddHostTransformation.psm1
using module ../../Classes/EmptyStringArgumentCompleter.psm1
using module ../../Classes/EmptyHashtableArgumentCompleter.psm1
using module ../../Classes/DockerImage.psm1

function Build-DockerImage {
    [CmdletBinding(
        SupportsShouldProcess,
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType([DockerImage])]
    [Alias('bddi')]
    param(
        [Parameter()]
        [string]
        $Path = '.',

        [Parameter()]
        [string]
        $DockerFile = './Dockerfile',

        # Tags are not mandatory by the docker engine so this argument may be $null,
        # but personally I always want a tag and if I forget one I'm annoyed at myself.
        [Parameter(Mandatory)]
        [AllowNull()]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string[]]
        $Tag,

        [Parameter()]
        [switch]
        $NoCache,

        [Parameter()]
        [switch]
        $Pull,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context,

        [Parameter()]
        [Alias('Dns', 'CustomDns')]
        [ArgumentCompleter([EmptyHashtableArgumentCompleter])]
        [DockerBuildAddHostTransformation()]
        [Dictionary[string, ipaddress]]
        $AddHosts,

        [Parameter()]
        [Alias('BuildArgs')]
        [ArgumentCompleter([EmptyHashtableArgumentCompleter])]
        [hashtable]
        $Parameters,

        [Parameter()]
        [switch]
        $PassThru
    )
    process {
        $ArgumentList = @(
            'image'
            'build'
            $Path
            if ($DockerFile) { '--file'; $Dockerfile }
            if ($NoCache) { '--no-cache' }
            if ($Pull) { '--pull' }
            if ($Tag) { $Tag | ForEach-Object { '--tag'; $_ } }
            if ($AddHosts) { $AddHosts.Keys | ForEach-Object { '--add-host'; "${_}:$($AddHosts[$_])" } }
            if ($Parameters) { $Parameters.Keys | ForEach-Object { '--build-arg'; "${_}=$($Parameters[$_])" } }
            '--quiet'
        )

        # Oh how I wish there were a way to write progress AND get the id of the final image
        if ($PassThru) {
            $Id = Invoke-Docker -ArgumentList $ArgumentList -Context $Context
            if ($?) {
                Get-DockerImage -Id $Id
            }
        }
        else {
            Invoke-Docker -ArgumentList $ArgumentList -Context $Context | Write-Debug
        }

    }
}
