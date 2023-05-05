# Launch the docker daemon in a separate process
& '/usr/local/bin/dockerd-entrypoint.sh' &

# Launch an interactive powershell prompt

# This setup is designed for extensibility: derived containers will insert
# additional scripts into this directory, and use the same entrypoint to launch
# the docker daemon and open PowerShell.

Get-ChildItem -Path $PSScriptRoot/dind-pwsh-setup -Filter '*.ps1' | ForEach-Object {
    & $_.FullName
}