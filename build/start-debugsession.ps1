param(
    [string]
    $WorkspaceFolder = (Split-Path $PSScriptRoot -Parent),

    [ValidateSet('Debug', 'Release')]
    [string]
    $Configuration = 'Debug'
)

$ModulePath = switch ($Configuration) {
    'Debug' {
        Join-Path $WorkspaceFolder 'Docker.PowerShell.CLI.psd1'
    }
    'Release' {
        Join-Path $WorkspaceFolder 'build/Debug/Docker.PowerShell.CLI/Docker.PowerShell.CLI.psd1'
    }
    default {
        throw 'Invalid configuration'
    }
}

$script:Module = Import-Module $ModulePath -Force -PassThru

function Prompt {
    $LastCommand = Get-History -Count 1;
    [TimeSpan]$ElapsedTime = $LastCommand.EndExecutionTime - $LastCommand.StartExecutionTime;
    $ModuleText = "$($script:Module.Name)/$($script:Module.Version)";
    if ($script:Module.PrivateData.PSData.Prerelease) {
        $ModuleText += "-$($script:Module.PrivateData.PSData.Prerelease)";
    }; 
    "$($PSStyle.Foreground.BrightBlack)" +
    "$($ElapsedTime.ToString('mm\:ss\.fff'))`r`n@ $pwd" +
    "$($PSStyle.Reset)`n" +
    "[$($PSStyle.Foreground.Yellow)$PID$($PSStyle.Reset)] " +
    "$ModuleText> "
}

