using namespace System.Management.Automation
using namespace System.Collections.Generic
using module ../Classes/DockerContainerCompleter.psm1
using module ../Classes/DockerContextCompleter.psm1
using module ../Classes/EmptyStringArgumentCompleter.psm1

function Invoke-DockerCommand {
    [CmdletBinding(
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    param(
        [Parameter(Mandatory)]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string]
        $ContainerName,

        [Parameter(ValueFromRemainingArguments)]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string[]]
        $ArgumentList,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    $PassArgumentList = [List[string]]::new($ArgumentList)
    $PassArgumentList.Insert(0, 'exec')
    $PassArgumentList.Insert(1, $ContainerName)
    Invoke-Docker -ArgumentList $PassArgumentList -Context $Context
}