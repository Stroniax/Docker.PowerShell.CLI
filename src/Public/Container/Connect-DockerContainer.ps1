using module ../../Classes/DockerContainerCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1

function Connect-DockerContainer {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Internal.AutomationNull])]
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