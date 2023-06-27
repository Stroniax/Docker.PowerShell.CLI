Import-Module "$PSSCriptRoot/../Docker.PowerShell.CLI.psd1"

Describe 'Use-DockerContext' {
    BeforeAll {
        $script:Module = Get-Module Docker.PowerShell.CLI
        if (-not $script:Module) {
            $script:RemoveModule = Import-Module "$PSScriptRoot/../Docker.PowerShell.CLI.psd1" -PassThru -Force
        }
        $script:PreviousDockerContext = docker context show
        docker context create 'docker-powershell-cli-test-1' --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null
        docker context create 'docker-powershell-cli-test-2' --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null

        $script:MockInvokeDocker = @{
            CommandName     = 'Invoke-Docker'
            Verifiable      = $true
            ModuleName      = $script:Module.Name
            MockWith        = { }
            ParameterFilter = { $ArgumentList -contains 'context' -and $ArgumentList -contains 'use' }
        }
    }
    AfterAll {
        $script:RemoveModule | Where-Object { $_ } | Remove-Module -Force
        docker context use $script:PreviousDockerContext
        docker context rm 'docker-powershell-cli-test-1' 'docker-powershell-cli-test-2' 2>&1 | Out-Null
    }
    It 'does not error' {
        # Arrange

        # Act
        # Assert
        { Use-DockerContext 'docker-powershell-cli-test-1' -ErrorAction Stop } | Should -Not -Throw
    }
    It 'sets the current docker context' -TestCases @(
        @{ Name = 'docker-powershell-cli-test-1' }
        @{ Name = 'docker-powershell-cli-test-2' }
    ) {
        # Arrange

        # Act
        Use-DockerContext $Name

        # Assert
        docker context show | Should -Be $Name
    }
    It 'calls Invoke-Docker context use' {
        Mock Invoke-Docker -ModuleName $script:Module.Name { } -ParameterFilter { $ArgumentList -contains 'context' -and $ArgumentList -contains 'use' }

        Use-DockerContext 'docker-powershell-cli-test-1'

        Should -Invoke Invoke-Docker -Exactly -Times 1 -ModuleName $script:Module.Name
    }
    Context 'ScriptBlock' {
        BeforeEach {
            docker context use $script:PreviousDockerContext 2>&1 | Out-Null
        }
        It 'runs the script inside the specified context' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-1' }
        ) {
            # Arrange

            # Act
            Use-DockerContext $Name {
                # Assert
                docker context show | Should -Be $Name
            }
        }
        It 'reverts to the previous context' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-1' }
            @{ Name = 'docker-powershell-cli-test-2' }
        ) {
            # Arrange
            
            # Act
            Use-DockerContext $Name { }

            # Assert
            docker context show | Should -Be $script:PreviousDockerContext
        }
        It 'reverts even when the script fails' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-1' }
        ) {
            # Arrange
            $Script = {
                throw 'Script failure'
            }

            # Act
            { Use-DockerContext $Name $Script } | Should -Throw

            # Assert
            docker context show | Should -Be $script:PreviousDockerContext
        }
        It 'outputs the script output' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-1'; Result = 42 }
        ) {
            # Arrange
            $Script = { $Result }

            # Act
            $Actual = Use-DockerContext $Name $Script

            # Assert
            $Actual | Should -Be $Result
        }
        It 'fails when the script fails' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-1' }
        ) {
            # Arrange
            $Script = {
                throw 'Script failure'
            }

            # Act
            { Use-DockerContext $Name $Script -ErrorAction Stop } | Should -Throw
        }
        It 'does not run the script when the context is not found' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-3' }
        ) {
            # Arrange
            $Ran = $false
            $Script = { $Ran = $true }

            # Act
            try { Use-DockerContext $Name $Script } catch { }

            # Assert
            $Ran | Should -BeFalse
        }
        # This test ensures we can run the script 'inline' as if it were being run directly by the
        # caller. This will ensure that variables, etc., can be set inside the script.
        It 'runs the script in the function call scope' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-1' }
        ) {
            # Arrange
            $script:VariableValue = 'before'

            # Act
            Use-DockerContext $Name {
                $script:VariableValue = 'after'
            }

            # Assert
            $VariableValue | Should -Be 'after'
        }
        It 'doesn''t expose module internals' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-1' }
        ) {
            # Arrange
            $Script = {
                Get-Command Invoke-Docker -ErrorAction Ignore
            }

            # Act
            $Actual = Use-DockerContext $Name $Script

            # Assert
            $Actual | Should -BeNullOrEmpty
        }
    }
    Context 'Parameter ''-PassThru''' {
        It 'returns nothing when $false' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-1' }
            @{ Name = 'docker-powershell-cli-test-2' }
        ) {
            # Arrange

            # Act
            $Output = Use-DockerContext $Name -PassThru:$false

            # Assert
            $Output | Should -BeNullOrEmpty
        }
        It 'returns [DockerContext] when $true' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-1' }
            @{ Name = 'docker-powershell-cli-test-2' }
        ) {
            # Arrange

            # Act
            $Output = Use-DockerContext $Name -PassThru:$true

            # Assert
            $Output.GetType().Name | Should -Be 'DockerContext'
        }
    }
    Context 'Parameter ''-Name''' {
        It 'is case-insensitive' -TestCases @(
            @{ Name = 'docker-powershell-CLI-test-1' }
            @{ Name = 'Docker-PowerShell-Cli-Test-2' }
        ) {
            # Arrange

            # Act
            $Output = Use-DockerContext $Name -PassThru -ErrorAction Stop

            # Assert
            $Output.Name | Should -Be $Name
        }
        It 'does not support wildcards' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-*' }
            @{ Name = 'docker-powershell-cli-test?1' }
        ) {
            # Arrange
            Mock @script:MockInvokeDocker
    
            # Act

            # Assert
            { Use-DockerContext $Name } | Should -Throw -ErrorId 'ContextNameNotFound,Use-DockerContext'
        }
        Context 'when not found' {
            BeforeAll {
                # Start out using a known context
                docker context use $script:PreviousDockerContext
                $script:Context = try {
                    Use-DockerContext 'docker-powershell-cli-test-3' -PassThru
                }
                catch {
                    $script:e = $_
                }
            }
            It 'throws' {
                $script:e | Should -Not -BeNullOrEmpty
            }
            It 'reports FullyQualifiedErrorId ''ContextNameNotFound,Use-DockerContext''' {
                $script:e.FullyQualifiedErrorId | Should -Be 'ContextNameNotFound,Use-DockerContext'
            }
            It 'reports [ItemNotFoundException]' {
                $script:e.Exception | Should -BeOfType System.Management.Automation.ItemNotFoundException
            }
            It 'reports ErrorCategory ''ObjectNotFound''' {
                $script:e.CategoryInfo.Category | Should -Be 'ObjectNotFound'
            }
            It 'has no output' {
                $script:Context | Should -BeNullOrEmpty
            }
            It 'does not change the current context' {
                docker context show | Should -Be $script:PreviousDockerContext
            }
        }
    }
}
