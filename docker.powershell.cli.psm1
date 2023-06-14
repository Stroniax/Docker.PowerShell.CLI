using namespace System.Collections;
using namespace System.Diagnostics;
using namespace System.Collections.Generic;
using namespace System.Management.Automation;
using namespace System.Management.Automation.Language;
using module src/Classes/DockerContainerCompleter.psm1
using module src/Classes/DockerContextCompleter.psm1
using module src/Classes/DockerImageCompleter.psm1
using module src/Classes/ValidateDockerContext.psm1

#region Classes

#endregion Classes

#region Helper Functions

#endregion Helper Functions

#region Docker Container

#endregion Docker Container

#region Docker Image

#endregion Docker Image

#region Docker Version

#endregion

#region Docker Context
#endregion Docker Context

#region Miscellaneous Commands
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
    Invoke-Docker $PassArgumentList -Context $Context
}
#endregion Miscellaneous Commands
