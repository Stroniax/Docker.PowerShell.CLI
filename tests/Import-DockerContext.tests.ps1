#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
#Requires -Version 7.0

Describe 'Import-DockerContext' {
    BeforeAll {
        $Module = Get-Module Docker.PowerShell.CLI
        if (!$Module) {
            $script:RemoveModule = Import-Module "$PSScriptRoot/../Docker.PowerShell.CLI.psd1" -PassThru -Force
        }

        $ContextName = 'docker-powershell-cli-test-1'
        $script:NewContextName = 'docker-powershell-cli-test-3'
        docker context create $ContextName --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null
        $FilePath = 'Temp:/test-docker-context.tar'
        $FullFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FilePath)
        docker context export $ContextName $FullFilePath 2>&1 | Out-Null
    }
    AfterAll {
        $script:RemoveModule | Where-Object { $_ } | Remove-Module -Force

        docker context rm $ContextName $SecondContextName
    }
    AfterEach {
        docker context rm $script:NewContextName 2>&1 | Out-Null
    }

    Context 'parameter ''-Path''' {
        BeforeAll {
            # calls docker context list and context import
            # but the only "result" gotten from docker is if I call PassThru
            Mock Invoke-Docker -ModuleName Docker.PowerShell.CLI { }
        }
        It 'cannot be null' {
            { Import-DockerContext -Path $null -name $script:NewContextName } | Should -Throw
        }
        It 'cannot be empty' {
            { Import-DockerContext -Path '' -name $script:NewContextName } | Should -Throw
        }
        It 'reports [ItemNotFoundException] when it does not refer to an existing path' -TestCases @(
            @{ Path = 'la-di-da' }
            @{ Path = 'C:/la-di-da' }
            @{ Path = 'Temp:/la-di-da' }
            @{ Path = 'this^is"n.va''lid' }
        ) {
            Import-DockerContext -Path $Path -name $script:NewContextName -ErrorAction SilentlyContinue -ErrorVariable e

            $e.Exception | Should -BeOfType 'System.Management.Automation.ItemNotFoundException'
            $e.FullyQualifiedErrorId | Should -Be 'PathNotFound,Microsoft.PowerShell.Commands.ResolvePathCommand'
        }
        It 'is successful when the path exists' {
            {
                Import-DockerContext -Path $FilePath -name $NewContextName -ErrorAction Stop
            } | Should -Not -Throw
        }
        It 'is successful when a path matches the wildcard pattern' {
            {
                Import-DockerContext -Path 'Temp:/*.tar' -name $script:NewContextName -ErrorAction Stop
            } | Should -Not -Throw
        }
        It 'supports paths relative from the current location' {
            Push-Location Temp:\

            try {
                { Import-DockerContext -Path 'test-docker-context.tar' -name $script:NewContextName -ErrorAction Stop } | Should -Not -Throw
            }
            finally {
                Pop-Location
            }
        }
    }
    Context 'parameter ''-LiteralPath''' {
        It 'accepts a value from the pipeline' -TestCases @(
            @{ LiteralPath = 'Temp:/test-docker-context.tar' }
        ) {
            Mock Invoke-Docker -ModuleName Docker.PowerShell.CLI { }
            Mock Resolve-Path { param($LiteralPath) @{ ProviderPath = $LiteralPath } } -ParameterFilter { $LiteralPath } -Verifiable -ModuleName Docker.PowerShell.CLI

            [pscustomobject]@{ LiteralPath = $LiteralPath } | Import-DockerContext -name $script:NewContextName

            Should -InvokeVerifiable Resolve-Path
        }
        It 'cannot be null' {
            { Import-DockerContext -LiteralPath $null -name $script:NewContextName } | Should -Throw
        }
        It 'cannot be empty' {
            { Import-DockerContext -LiteralPath '' -name $script:NewContextName } | Should -Throw
        }
        It 'reports [ItemNotFoundException] when not found' -TestCases @(
            @{ Path = 'la-di-da' }
            @{ Path = 'Temp:/la-di-da' }
            @{ Path = 'this^is"n.va''lid' }
        ) {
            Import-DockerContext -LiteralPath $Path -name $script:NewContextName -ErrorAction SilentlyContinue -ErrorVariable e

            $e.Exception | Should -BeOfType 'System.Management.Automation.ItemNotFoundException'
            $e.FullyQualifiedErrorId | Should -Be 'PathNotFound,Microsoft.PowerShell.Commands.ResolvePathCommand'
        }
        It 'reports [ItemNotFoundException] when the path contains wildcards' {
            Import-DockerContext -LiteralPath 'Temp:/*.tar' -name $script:NewContextName -ErrorAction SilentlyContinue -ErrorVariable e

            $e.Exception | Should -BeOfType 'System.Management.Automation.ItemNotFoundException'
            $e.FullyQualifiedErrorId | Should -Be 'PathNotFound,Microsoft.PowerShell.Commands.ResolvePathCommand'
        }
        It 'does not support paths relative from the current location' {
            Push-Location Temp:\

            try {
                { Import-DockerContext -LiteralPath 'test-docker-context.tar' -name $script:NewContextName -ErrorAction Stop } | Should -Throw
            }
            finally {
                Pop-Location
            }
        }
    }
    Context 'parameter ''-PassThru''' {
        BeforeAll {
            Mock Resolve-Path { param($Path, $LiteralPath) @{ ProviderPath = $Path ?? $LiteralPath } } -ModuleName Docker.PowerShell.CLI
            Mock Invoke-Docker -ModuleName Docker.PowerShell.CLI {
                param($ArgumentList)

                if ($ArgumentList -contains 'import') {
                    # hijack no-op
                }
                elseif ($ArgumentList -contains '{{ .Name }}') {
                    # tests for existing contexts
                    'default'
                }
                else {
                    throw "Unexpected argument list in mock: $ArgumentList"
                }
            }
        }
        It 'when $false, has no output' -TestCases @(
            @{ Bind = @{ Path = 'some-file-path.tar'; Name = 'some-context' } }
            @{ Bind = @{ LiteralPath = 'fake-literal-path.baz'; Name = 'context-baz' } }
        ) {
            # Arrange

            # Act
            $Output = Import-DockerContext @Bind

            # Assert
            $Output | Should -BeNullOrEmpty
        }
        It 'when $true, returns output of `Get-DockerContext`' -TestCases @(
            @{ Bind = @{ Path = 'some-file-path.tar'; Name = 'some-context' }; Expected = 'MockGetDockerContextOutput' }
            @{ Bind = @{ LiteralPath = 'fake-literal-path.baz'; Name = 'context-baz' }; Expected = 'Other-Test' }
        ) {
            # Arrange
            Mock Get-DockerContext { $Expected } -ModuleName Docker.PowerShell.CLI

            # Act
            $Output = Import-DockerContext @Bind -PassThru
            
            # Assert
            $Output | Should -Be $Expected
        }
        It 'when $true, passes $Name to Get-DockerContext' -TestCases @(
            @{ Bind = @{ Path = 'some-file-path.tar'; Name = 'some-context' } }
            @{ Bind = @{ LiteralPath = 'fake-literal-path.baz'; Name = 'context-baz' } }
        ) {
            # Arrange
            Mock Get-DockerContext { 'MockGetDockerContextOutput' } -ModuleName Docker.PowerShell.CLI -Verifiable -ParameterFilter { $Name -eq $Bind.Name }

            # Act
            Import-DockerContext @Bind -PassThru
            
            # Assert
            Should -InvokeVerifiable Get-DockerContext
        }
    }
    Context 'parameter ''-Name''' {
        BeforeAll {
            Mock Resolve-Path { param($Path, $LiteralPath) @{ ProviderPath = $Path ?? $LiteralPath } } -ModuleName Docker.PowerShell.CLI
            Mock Invoke-Docker { <# no-op #> } -ParameterFilter { $ArgumentList -contains 'import' } -ModuleName Docker.PowerShell.CLI
        }
        It 'cannot be null' {
            { Import-DockerContext -Path $FilePath -name $null } | Should -Throw
        }
        It 'cannot be empty' {
            { Import-DockerContext -Path $FilePath -name '' } | Should -Throw
        }
        It 'when associated with an existing context, reports InvalidOperationException' -TestCases @(
            @{ Bind = @{ Path = 'some-path'; Name = 'default' } }
            @{ Bind = @{ LiteralPath = 'some-path'; Name = 'docker' } }
        ) {
            # Arrange
            Mock Invoke-Docker { $Bind.Name } -ModuleName Docker.PowerShell.CLI -ParameterFilter { $ArgumentList -contains '{{ .Name }}' }

            # Act
            Import-DockerContext @Bind -ErrorAction SilentlyContinue -ErrorVariable e

            # Assert
            $e.Exception | Should -BeOfType 'System.InvalidOperationException'
            $e.FullyQualifiedErrorId | Should -Be 'ContextExists,Import-DockerContext'
            $e.CategoryInfo.Category | Should -Be 'InvalidArgument'
            $e.TargetObject | Should -Be $Bind.Name
        }
        It 'when the context does not exist, is successful' -TestCases @(
            @{ Bind = @{ Path = 'some-path'; Name = 'default' } }
            @{ Bind = @{ LiteralPath = 'some-path'; Name = 'docker' } }
        ) {
            # Arrange
            Mock Invoke-Docker {
                param($ArgumentList)

                if ($ArgumentList -contains '{{ .Name }}') {
                    # no output
                }
                else {
                    throw "Unexpected argument list in mock: $ArgumentList"
                }
            } -ModuleName Docker.PowerShell.CLI

            # Act
            {
                Import-DockerContext @Bind -ErrorAction Stop
                # Assert
            } | Should -Not -Throw
        }
    }
    Context 'parameter ''-WhatIf''' {
        It 'when $true, does not call ''docker context import''' {
            # Arrange
            Mock Invoke-Docker { <# no-op #> } -ParameterFilter { $ArgumentList -contains 'import' } -ModuleName Docker.PowerShell.CLI -Verifiable

            # Act
            Import-DockerContext -Path $FilePath -name $script:NewContextName -WhatIf

            # Assert
            Should -Not -InvokeVerifiable Invoke-Docker
        }
        It 'when $false, calls ''docker context import''' -TestCases @(
            @{ Bind = @{ Path = 'test-fake-path'; Name = 'default' } }
            @{ Bind = @{ LiteralPath = 'not-even-literal'; Name = 'docker' } }
        ) {
            # Arrange
            Mock Resolve-Path { param($Path, $LiteralPath) @{ ProviderPath = $Path ?? $LiteralPath } } -ModuleName Docker.PowerShell.CLI
            Mock Invoke-Docker { <# doesn't exist #> } -ParameterFilter { $ArgumentList -contains '{{ .Name }}' } -ModuleName Docker.PowerShell.CLI
            Mock Invoke-Docker { <# no-op #> } -ParameterFilter { $ArgumentList -contains 'import' } -ModuleName Docker.PowerShell.CLI -Verifiable

            # Act
            Import-DockerContext @Bind -WhatIf:$false

            # Assert
            Should -InvokeVerifiable Invoke-Docker
        }
    }
}