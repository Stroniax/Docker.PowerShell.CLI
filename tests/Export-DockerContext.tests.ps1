#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

Describe 'Export-DockerContext' {
    BeforeAll {
        $Module = Get-Module Docker.PowerShell.CLI
        if (!$Module) {
            $script:RemoveModule = Import-Module "$PSScriptRoot/../Docker.PowerShell.CLI.psd1" -PassThru -Force
        }

        $ContextName = 'docker-powershell-cli-test-1'
        $SecondContextName = 'docker-powershell-cli-test-2'
        $script:FakeContextName = 'docker-powershell-cli-test-3'
        docker context create $ContextName --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null
        docker context create $SecondContextName --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null
    }
    AfterAll {
        $script:RemoveModule | Where-Object { $_ } | Remove-Module -Force

        docker context rm $ContextName $SecondContextName
    }

    It 'reports [IOException] when the file exists and ''-Force'' is not present' {
        # Arrange
        $Path = 'Temp:/test-context'
        New-Item -Path $Path | Out-Null
        $ProviderPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

        # Act
        try {
            Export-DockerContext -Name $ContextName -Path $Path -ErrorAction SilentlyContinue -ErrorVariable exportError
        }
        finally {
            Remove-Item -Path $Path
        }
    
        # Assert
        $exportError.Exception | Should -BeOfType 'System.IO.IOException'
        $exportError.FullyQualifiedErrorId | Should -Be 'FileExists,Export-DockerContext'
        $exportError.ErrorDetails.Message | Should -Be "The file '$ProviderPath' already exists."
    }
    It 'does not overwrite a file when ''-Force'' is not present' {
        # Arrange
        $Path = 'Temp:/test-context'
        $LastEditTime = (New-Item -Path $Path).LastWriteTime

        # Act
        try {
            Export-DockerContext -Name $ContextName -Path $Path -ErrorAction Ignore
            $ActualEditTime = (Get-Item -Path $Path).LastWriteTime
        }
        finally {
            Remove-Item -Path $Path
        }

        # Assert
        $LastEditTime | Should -Be $ActualEditTime
    }
    It 'reports [DirectoryNotFoundException] when the parent directory does not exist' {
        # Arrange
        $Path = 'Temp:/test-context-dir/test-context'
        $Parent = Split-Path -Path $Path -Parent
        if (Test-Path -Path $Parent) {
            Remove-Item -Path $Parent -ErrorAction Stop
        }
        $ProviderPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Parent)

        # Act
        Export-DockerContext -Name $ContextName -Path $Path -ErrorAction SilentlyContinue -ErrorVariable exportError

        # Assert
        $exportError.Exception | Should -BeOfType 'System.IO.DirectoryNotFoundException'
        $exportError.FullyQualifiedErrorId | Should -Be 'DirectoryNotFound,Export-DockerContext'
        $exportError.ErrorDetails.Message | Should -Be "Could not find a part of the path '$ProviderPath'."
        $exportError.TargetObject | Should -Be $ProviderPath
    }
    It 'creates the file when ''-Force'' is not present' {
        # Arrange
        $Path = "Temp:/$(New-Guid)"

        # Act
        Export-DockerContext -Name $ContextName -Path $Path -ErrorAction Ignore

        # Assert
        Test-Path -Path $Path | Should -BeTrue
    }
    It 'overwrites the file when ''-Force'' is present' {
        # Arrange
        # Ensure the operation will not fail due to the file already existing
        $ErrorActionPreference = 'Stop'

        $Path = "Temp:/$(New-Guid)"
        $InitialEditTime = (New-Item -Path $Path).LastWriteTime

        # Act
        Export-DockerContext -Name $ContextName -Path $Path -Force -ErrorAction Ignore
        $ActualEditTime = (Get-Item -Path $Path).LastWriteTime

        # Assert
        $ActualEditTime | Should -BeGreaterThan $InitialEditTime
    }
    It 'returns [FileInfo] when ''-PassThru'' is present' {
        # Arrange
        $Path = "Temp:/$(New-Guid)"
        $ProviderPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

        # Act
        $Result = Export-DockerContext -Name $ContextName -Path $Path -PassThru -ErrorAction Ignore

        # Assert
        $Result | Should -BeOfType 'System.IO.FileInfo'
        $Result.FullName | Should -Be $ProviderPath
    }
    It 'returns nothing when ''-PassThru'' is not present' {
        # Arrange
        $Path = "Temp:/$(New-Guid)"

        # Act
        $Result = Export-DockerContext -Name $ContextName -Path $Path -ErrorAction Ignore

        # Assert
        $Result | Should -BeNullOrEmpty
    }
    It 'does nothing when the name is not found' {
        # Arrange
        $Path = "Temp:/$(New-Guid)"

        # Act
        $Result = Export-DockerContext -Name $FakeContextName -Path $Path -ErrorAction Ignore

        # Assert
        $Result | Should -BeNullOrEmpty
    }
    It 'reports an error when the name is not found' {
        # Arrange
        $Path = "Temp:/$(New-Guid)"

        # Act
        try {
            Export-DockerContext -Name $FakeContextName -Path $Path -ErrorAction SilentlyContinue -ErrorVariable exportError
        }
        finally {
            Remove-Item -Path $Path -ErrorAction Ignore
        }

        # Assert
        $exportError.Exception | Should -BeOfType 'System.Management.Automation.ItemNotFoundException'
        $exportError.FullyQualifiedErrorId | Should -Be 'ContextNameNotFound,Get-DockerContext'
    }
    It 'reports an error when the name is not found when it has wildcards' {
        # Arrange
        $Path = "Temp:/$(New-Guid)"

        # Act
        try {
            Export-DockerContext -Name "$FakeContextName*" -Path $Path -ErrorAction SilentlyContinue -ErrorVariable exportError
        }
        finally {
            Remove-Item -Path $Path -ErrorAction Ignore
        }

        # Assert
        $exportError.Exception | Should -BeOfType 'System.Management.Automation.ItemNotFoundException'
        $exportError.FullyQualifiedErrorId | Should -Be 'ContextNameNotFound,Export-DockerContext'
    }
    It 'does nothing when the name is ambiguous' {
        # Arrange
        $Path = "Temp:/$(New-Guid)"

        # Act
        $Result = Export-DockerContext -Name 'docker-powershell-cli-test-?' -Path $Path -ErrorAction Ignore -PassThru

        # Assert
        $Result | Should -BeNullOrEmpty
    }
    It 'reports [AmbiguousMatchException] when the name is ambiguous' {
        # Arrange
        $Path = "Temp:/$(New-Guid)"

        # Act
        Export-DockerContext -Name 'docker-powershell-cli-test-?' -Path $Path -ErrorAction SilentlyContinue -ErrorVariable exportError

        # Assert
        $exportError.Exception | Should -BeOfType 'System.Reflection.AmbiguousMatchException'
        $exportError.FullyQualifiedErrorId | Should -Be 'ContextNameAmbiguous,Export-DockerContext'
    }
    It 'does nothing when the ''-WhatIf'' parameter is specified' {
        # Arrange
        $Path = "Temp:/$(New-Guid)"

        # Act
        $Result = Export-DockerContext -Name $ContextName -Path $Path -WhatIf -ErrorAction Ignore -PassThru

        # Assert
        $Result | Should -BeNullOrEmpty
    }
}