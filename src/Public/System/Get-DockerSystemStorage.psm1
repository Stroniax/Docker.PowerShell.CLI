using namespace System.Management.Automation
using module ../../Classes/DockerSystemStorage.psm1
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Private/Invoke-Docker.ps1

function Get-DockerSystemStorage {
    [CmdletBinding(
        RemotingCapability = [RemotingCapability]::PowerShell,
        PositionalBinding = $false
    )]
    [OutputType([DockerSystemStorage])]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $ArgumentList = [List[string]]::new()
        $ArgumentList.Add('system')
        $ArgumentList.Add('df')
        $ArgumentList.Add('--format')
        $ArgumentList.Add('{{ json . }}')

        $DockerSystemDfVerbose = Invoke-Docker system df --format '{{ json . }}' --verbose -Context $Context | ConvertFrom-Json
        if (!$?) { return }
        $DockerSystemDf = Invoke-Docker system df --format '{{ json . }}' -Context $Context | ConvertFrom-Json
        if (!$?) { return }

        $Storage = [DockerSystemStorage]::new($DockerSystemDfVerbose, $DockerSystemDf)
        $Storage.PSObject.Properties.Add([psnoteproperty]::new('PSDockerContext', $Context))
        $Storage
    }
}