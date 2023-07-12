#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

Describe 'New-DockerContext' {
    BeforeAll {
        $Module = Get-Module Docker.PowerShell.CLI
        if (!$Module) {
            $script:RemoveModule = Import-Module "$PSScriptRoot/../Docker.PowerShell.CLI.psd1" -PassThru -Force
        }

        $ContextName = 'docker-powershell-cli-test-1'
        docker context create $ContextName --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null
    }
    AfterAll {
        docker context rm $ContextName 2>&1 | Out-Null
        $script:RemoveModule | Where-Object { $_ } | Remove-Module -Force
    }
    AfterEach {
        docker context rm 'docker-powershell-cli-test-2' 2>&1 | Out-Null
    }
    It 'ensures the context does not exist' {
        { New-DockerContext -Name $ContextName -DockerHost 'tcp://myserver:2376' -ErrorAction Stop } | Should -Throw
    }
    It 'calls Set-DockerContext' {
        # Arrange
        Mock Set-DockerContext -ModuleName Docker.PowerShell.CLI -Verifiable

        # Act
        New-DockerContext -Name 'docker-powershell-cli-test-2' -DockerHost 'tcp://myserver:2376'

        # Assert
        Should -Invoke Set-DockerContext -Times 1 -Exactly -ModuleName Docker.PowerShell.CLI
    }
    It 'outputs [DockerContext]' {
        # Arrange

        # Act
        $Result = New-DockerContext -Name 'docker-powershell-cli-test-2' -DockerHost 'tcp://myserver:2376'

        # Assert
        $Result | ForEach-Object { $_.GetType().Name } | Should -Be 'DockerContext'
    }
    It 'does nothing if ''-WhatIf'' is specified' {
        # Arrange

        # Act
        $Result = New-DockerContext -Name 'docker-powershell-cli-test-2' -DockerHost 'tcp://myserver:2376' -WhatIf

        # Assert
        $Result | Should -BeNullOrEmpty
        (docker context list --format '{{.Name}}') | Should -Not -Contain 'docker-powershell-cli-test-2'
    }
    It 'has all the parameters of ''Set-DockerContext'' except ''-PassThru''' {
        $NewDockerContext = Get-Command New-DockerContext
        $SetDockerContext = Get-Command Set-DockerContext

        foreach ($Key in $SetDockerContext.Parameters.Keys) {
            if ($Key -eq 'PassThru') {
                continue
            }

            $NewDockerContext.Parameters.Keys | Should -Contain $Key
            $Parameter = $NewDockerContext.Parameters[$Key]
            $Parameter.Aliases | Should -Be $NewDockerContext.Parameters[$Key].Aliases -Because "Parameter '$Key' should have the same aliases."
            $Parameter.ParameterType | Should -Be $NewDockerContext.Parameters[$Key].ParameterType -Because "Parameter '$Key' should have the same parameter type."
        }
    }
}
