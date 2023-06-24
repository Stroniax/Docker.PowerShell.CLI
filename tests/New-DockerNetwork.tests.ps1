#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

Describe 'New-DockerNetwork' {
    BeforeAll {
        $global:PSModuleAutoLoadingPreference = 'None'
        $Module = Get-Module 'Docker.PowerShell.CLI'
        if (!$Module) {
            $script:RemoveModule = Import-Module "$PSScriptRoot/../Docker.PowerShell.CLI.psd1" -Force -PassThru
        }
    }
    AfterAll {
        $script:RemoveModule | Where-Object { $_ } | Remove-Module -Force
    }
    AfterEach {
        if (docker network list --filter 'name=docker-powershell-cli-test-1') {
            docker network remove 'docker-powershell-cli-test-1' 2>&1 | Out-Null
        }
    }
    It 'has no output for -WhatIf' -TestCases @(
        @{ Name = 'docker-powershell-cli-test-1' }
    ) {
        # Arrange

        # Act
        $Output = New-DockerNetwork $Name -WhatIf

        # Assert
        $Output | Should -BeNullOrEmpty
    }
    It 'does not run docker for -WhatIf' -TestCases @(
        @{ Name = 'docker-powershell-cli-test-1' }
    ) {
        # Arrange
        Mock Invoke-Docker -ModuleName Docker.PowerShell.CLI -Verifiable {}

        # Act
        New-DockerNetwork $Name -WhatIf

        # Assert
        Should -Invoke Invoke-Docker -Exactly -Times 0 -ModuleName Docker.PowerShell.CLI
    }
    It 'normally calls Invoke-Docker' -TestCases @(
        @{ Name = 'docker-powershell-cli-test-1' }
    ) {
        # Arrange
        ## Ensure Invoke-Docker is called
        Mock Invoke-Docker -ModuleName Docker.PowerShell.CLI -Verifiable { }
        ## Don't allow Get-DockerNetworkInternal to fail or call Invoke-Docker
        Mock Get-DockerNetworkInternal -ModuleName Docker.PowerShell.CLI { }

        # Act
        New-DockerNetwork $Name

        # Assert
        Should -Invoke Invoke-Docker -Exactly -Times 1 -ModuleName Docker.PowerShell.CLI
    }
    It 'is successful for -WhatIf' {
        # Arrange

        # Act
        { New-DockerNetwork 'docker-powershell-cli-test-1' -WhatIf -ErrorAction Stop } | Should -Not -Throw
    }
    It 'has no output if it fails' -TestCases @(
        @{ Name = 'docker-powershell-cli-test-1' }
    ) {
        # Arrange
        New-DockerNetwork $Name

        try {
            # Act
            $Output = New-DockerNetwork $Name -ErrorAction SilentlyContinue

            # Assert
            $Output | Should -BeNullOrEmpty
        }
        finally {
            docker network remove $Name 2>&1 | Out-Null
        }
    }
    It 'reports error if the network already exists' {
        # Arrange
        docker network create 'docker-powershell-cli-test-1'

        # Act
        New-DockerNetwork -Name 'docker-powershell-cli-test-1' -ErrorVariable e -ErrorAction SilentlyContinue

        # Assert
        $e | Should -HaveCount 1
    }
    It 'returns [DockerNetwork]' {
        # Arrange

        # Act
        $Network = New-DockerNetwork -Name 'docker-powershell-cli-test-1'

        # Assert
        $Network.GetType().Name | Should -Be 'DockerNetwork'
    }
    It 'returns one object' {
        # Arrange

        # Act
        $Network = New-DockerNetwork -Name 'docker-powershell-cli-test-1'

        # Assert
        $Network | Should -HaveCount 1
    }
    It 'has the provided name' -TestCases @(
        @{ Name = 'docker-powershell-cli-test-1' }
        @{ Name = 'docker-powershell-cli-test-2' }
    ) {
        # Arrange

        try {
            # Act
            $Network = New-DockerNetwork $Name

            # Assert
            $Network.Name | Should -Be $Name
        }
        finally {
            # Cleanup
            docker network remove $Name 2>&1 | Out-Null
        }
    }
}