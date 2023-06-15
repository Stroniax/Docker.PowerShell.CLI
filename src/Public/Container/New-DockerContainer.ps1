using namespace System.Collections.Generic
using namespace System.Management.Automation
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/DockerImageCompleter.psm1
using module ../../Classes/DockerContainer.psm1
using module ../../Classes/EmptyStringArgumentCompleter.psm1
using module ../../Classes/EmptyIpAddressArgumentCompleter.psm1
using module ../../Classes/EmptyHashtableArgumentCompleter.psm1
using module ../../Classes/NumericArgumentCompleter.psm1

function New-DockerContainer {
    [CmdletBinding(
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType([DockerContainer])]
    [Alias('ndc')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $ImageName,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('ContainerName')]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $Name,

        [Parameter()]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $HostName,

        [Parameter()]
        [ArgumentCompleter([EmptyIpAddressArgumentCompleter])]
        [IPAddress]
        $IPAddress,

        [Parameter()]
        [switch]
        $Interactive,

        [Parameter()]
        [ArgumentCompleter([EmptyHashtableArgumentCompleter])]
        [Hashtable]
        $Labels,

        [Parameter()]
        [ArgumentCompleter([EmptyHashtableArgumentCompleter])]
        [Hashtable]
        $Environment,

        [Parameter()]
        [ValidateSet('always', 'missing', 'never')]
        [string]
        $PullBehavior,

        [Parameter()]
        [switch]
        $ReadOnly,

        [Parameter()]
        [switch]
        $AutoRemove,

        [Parameter()]
        [ArgumentCompleter([NumericArgumentCompleter])]
        [int]
        $TimeoutSeconds,

        [Parameter()]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $WorkingDirectory,

        # Any additional parameters to pass to the docker cli
        [Parameter()]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string[]]
        $Parameters,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        [List[string]]$ArgumentList = @(
            'container'
            'create'
        )

        if ($Name) {
            $ArgumentList.Add('--name')
            $ArgumentList.Add($Name)
        }

        if ($HostName) {
            $ArgumentList.Add('--hostname')
            $ArgumentList.Add($HostName)
        }

        if ($IPAddress) {
            $ArgumentList.Add('--ip')
            $ArgumentList.Add($IPAddress)
        }

        if ($Interactive) {
            $ArgumentList.Add('--interactive')
        }

        if ($Labels) {
            foreach ($k in $Labels.Keys) {
                $ArgumentList.Add('--label')
                $ArgumentList.Add("$k=$($Labels[$k])")
            }
        }

        if ($Environment) {
            foreach ($k in $Environment.Keys) {
                $ArgumentList.Add('--env')
                $ArgumentList.Add("$k=$($Environment[$k])")
            }
        }

        if ($PullBehavior) {
            $ArgumentList.Add('--pull')
            $ArgumentList.Add($PullBehavior)
        }

        if ($ReadOnly) {
            $ArgumentList.Add('--read-only')
        }

        if ($AutoRemove) {
            $ArgumentList.Add('--rm')
        }

        if ($TimeoutSeconds) {
            $ArgumentList.Add('--timeout')
            $ArgumentList.Add($TimeoutSeconds)
        }

        if ($WorkingDirectory) {
            $ArgumentList.Add('--workdir')
            $ArgumentList.Add($WorkingDirectory)
        }

        if ($Parameters) {
            foreach ($p in $Parameters) {
                $ArgumentList.Add($p)
            }
        }

        $ArgumentList.Add($ImageName)

        if (!$PSCmdlet.ShouldProcess(
                "Creating container '$Name' from image '$ImageName'.",
                "Create container '$Name' from image '$ImageName'?",
                "docker $ArgumentList")) {
            return
        }

        $Id = Invoke-Docker -ArgumentList $ArgumentList -Context $Context 
        if ($?) {
            Get-DockerContainerInternal -Id $Id -Context $Context
        }
    }
}
