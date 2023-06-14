using namespace System.Management.Automation

function Get-DockerVersion {
    [CmdletBinding(
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    [OutputType('Docker.DockerVersion')]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        Invoke-Docker version --format '{{ json . }}' -Context $Context | ForEach-Object {
            $pso = $_ | ConvertFrom-Json
            $pso.PSTypeNames.Insert(0, 'Docker.DockerVersion')
            $pso.Client.PSTypeNames.Insert(0, 'Docker.ClientVersion')
            $pso.Server.PSTypeNames.Insert(0, 'Docker.ServerVersion')
            $ModuleVersionInfo = [pscustomobject]@{
                Version    = $MyInvocation.MyCommand.Module.Version
                Prerelease = $MyInvocation.MyCommand.Module.PrivateData.PSData.Prerelease
                PSTypeName = 'Docker.ModuleVersion'
            }
            $pso.PSObject.Members.Add([PSNoteProperty]::new('Module', $ModuleVersionInfo))
            $pso
        }
    }
}