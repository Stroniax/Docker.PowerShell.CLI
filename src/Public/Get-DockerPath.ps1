function Get-DockerPath {
    [CmdletBinding()]
    param()
    process {
        Get-Item $Docker
    }
}