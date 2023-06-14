using module ../../src/Classes/DockerContainerCompleter.psm1
using module ../../src/Classes/DockerContextCompleter.psm1

function Connect-DockerContainer {
    [CmdletBinding()]
    [Alias('ccdc')]
    param(
        [Parameter(Mandatory)]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string]
        $ContainerName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        Invoke-Docker attach $ContainerName -Context $Context
    }
}