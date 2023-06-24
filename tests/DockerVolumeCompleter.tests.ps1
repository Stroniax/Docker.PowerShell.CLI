#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
#Requires -Version 6.0

Describe '[DockerVolumeCompleter]' {
    BeforeAll {
        $global:PSModuleAutoLoadingPreference = 'None'
        $script:Module = Get-Module 'Docker.PowerShell.CLI'
        if (-not $script:Module) {
            $script:RemoveModule = $script:Module = Import-Module "$PSScriptRoot/../Docker.PowerShell.CLI.psd1" -Force -PassThru -ArgumentList $true
        }
        $script:Type = & $script:Module { [DockerVolumeCompleter] }
        $script:Completer = [Activator]::CreateInstance($Type)

        $script:MockModule = (Get-Module 'DockerVolumeCompleter' -All) ?? (Get-Module 'Docker.PowerShell.CLI')
    }
    AfterAll {
        $script:RemoveModule | Where-Object { $_ } | Remove-Module -Force
    }
    Context 'with volumes' {
        BeforeAll {
            Mock Get-DockerVolume -Verifiable -ModuleName $script:MockModule.Name {
                param($Name)
                @(
                    [pscustomobject]@{ Name = 'test1-uno'; Scope = 'local'; Driver = 'local'; Group = 'N/A' }
                    [pscustomobject]@{ Name = 'test2-dos'; Scope = 'global'; Driver = 'local'; Group = 'N/A' }
                    [pscustomobject]@{ Name = 'test3-tres'; Scope = 'local'; Driver = 'local'; Group = 'N/A' }
                    [pscustomobject]@{ Name = 'test4-quatro'; Scope = 'local'; Driver = 'local'; Group = 'N/A' }
                ) | Where-Object Name -Like $Name
            }
        }
        It 'calls Get-DockerVolume' -TestCases @(
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Name'; WordToComplete = 'test' }
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Driver'; WordToComplete = 'test' }
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Scope'; WordToComplete = $null }
            @{ CommandName = 'Remove-DockerVolume'; ParameterName = 'Name'; WordToComplete = '' }
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Name'; WordToComplete = "'*" }
            @{ CommandName = 'Test-Command'; ParameterName = 'Abnormal'; WordToComplete = '"' }
        ) {
            # Arrange

            # Act
            $Completer.CompleteArgument($CommandName, $ParameterName, $WordToComplete, $null, @{})

            # Assert
            Should -Invoke Get-DockerVolume -Exactly -Times 1 -ModuleName $script:MockModule.Name
        }
        It 'should pass -Context from bound parameters to Get-DockerVolume' -TestCases @(
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Name'; WordToComplete = 'test'; FakeBoundParameters = @{} }
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Driver'; WordToComplete = 'test'; FakeBoundParameters = @{Context = 'test-c' } }
        ) {
            # Arrange

            # Act
            $script:Completer.CompleteArgument($CommandName, $ParameterName, $WordToComplete, $null, $FakeBoundParameters)

            # Assert
            Should -Invoke Get-DockerVolume -Exactly -Times 1 -ParameterFilter { $Context -eq $FakeBoundParameters.Context } -ModuleName $script:MockModule.Name
        }
        It 'should pass a wildcarded term to Get-DockerVolume' -TestCases @(
            @{ CommandName = ''; ParameterName = ''; WordToComplete = 'test' }
        ) {
            # Arrange
            
            # Act
            $script:Completer.CompleteArgument($CommandName, $ParameterName, $WordToComplete, $null, @{})

            # Assert
            Should -Invoke Get-DockerVolume -Exactly -Times 1 -ParameterFilter { [WildcardPattern]::ContainsWildcardCharacters($Name) } -ModuleName $script:MockModule.Name
        }
        It 'should trim quotes in call to Get-DockerVolume' -TestCases @(
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Name'; WordToComplete = "'test"; Expected = 'test*' }
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Name'; WordToComplete = '"test'; Expected = 'test*' }
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Scope'; WordToComplete = "'test'"; Expected = 'test*' }
            @{ CommandName = 'Test-Command'; ParameterName = 'Id'; WordToComplete = '"test"'; Expected = 'test*' }
        ) {
            # Arrange

            # Act
            $script:Completer.CompleteArgument($CommandName, $ParameterName, $WordToComplete, $null, @{})

            # Assert
            Should -Invoke Get-DockerVolume -Exactly -Times 1 -ParameterFilter { $Name -eq $Expected } -ModuleName $script:MockModule.Name
        }
        It 'should complete using matches' -TestCases @(
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Name'; WordToComplete = 'test'; Expected = 'test1-uno', 'test2-dos', 'test3-tres', 'test4-quatro' }
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Name'; WordToComplete = 'test1'; Expected = 'test1-uno' }
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Name'; WordToComplete = 'test1-uno'; Expected = 'test1-uno' }
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Name'; WordToComplete = '*1'; Expected = 'test1-uno' }
        ) {
            # Arrange

            # Act
            $Result = $script:Completer.CompleteArgument($CommandName, $ParameterName, $WordToComplete, $null, @{})

            # Assert
            $Result.CompletionText | Should -Be $Expected
        }
        It 'should complete matching original quotes' -TestCases @(
            @{ WordToComplete = "'test1"; Expected = "'test1-uno'" }
            @{ WordToComplete = '"test1'; Expected = '"test1-uno"' }
            @{ WordToComplete = "'test1'"; Expected = "'test1-uno'" }
            @{ WordToComplete = '"test1"'; Expected = '"test1-uno"' }
            @{ WordToComplete = 'test1'; Expected = 'test1-uno' }
        ) {
            # Arrange

            # Act
            $Result = $script:Completer.CompleteArgument('Get-DockerVolume', 'Name', $WordToComplete, $null, @{})

            # Assert
            $Result.CompletionText | Should -Be $Expected
        }
    }
    Context 'without volumes' {
        BeforeAll {
            Mock Get-DockerVolume -ModuleName $script:MockModule.Name {
                param(
                    [string]$Name
                )
                if (![WildcardPattern]::ContainsWildcardCharacters($Name)) {
                    Write-Error "No such volume: $Name"
                }
            }
        }
        It 'does not report an error' -TestCases @(
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Name'; WordToComplete = 'test' }
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Driver'; WordToComplete = 'test' }
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Scope'; WordToComplete = $null }
            @{ CommandName = 'Remove-DockerVolume'; ParameterName = 'Name'; WordToComplete = '' }
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Name'; WordToComplete = "'*" }
        ) {
            {
                # Arrange
                $ErrorActionPreference = 'Stop'

                # Act
                $script:Completer.CompleteArgument($CommandName, $ParameterName, $WordToComplete, $null, @{})

                # Assert
            } | Should -Not -Throw
        }
        It 'has no completions' -TestCases @(
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Name'; WordToComplete = 'test' }
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Driver'; WordToComplete = 'test' }
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Scope'; WordToComplete = $null }
            @{ CommandName = 'Remove-DockerVolume'; ParameterName = 'Name'; WordToComplete = '' }
            @{ CommandName = 'Get-DockerVolume'; ParameterName = 'Name'; WordToComplete = "'*" }
        ) {
            # Arrange

            # Act
            $Completions = $script:Completer.CompleteArgument($CommandName, $ParameterName, $WordToComplete, $null, @{})

            # Assert
            $Completions | Should -BeNullOrEmpty
        }
    }
    Context 'when docker is unavailable' {
        BeforeAll {
            Mock Get-DockerVolume -ModuleName $script:MockModule.Name {
                Write-Error 'docker: docker daemon unreachable'
            }
        }
        It 'returns an empty collection' {
            # Arrange

            # Act
            $Completions = $script:Completer.CompleteArgument('Get-DockerVolume', 'Name', 'test', $null, @{})

            # Assert
            $Completions.Count | Should -Be 0
            $null -eq $Completions | Should -BeFalse
        }
    }
}