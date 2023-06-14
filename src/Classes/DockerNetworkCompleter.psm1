class DockerNetworkCompleter : System.Management.Automation.IArgumentCompleter {
    [System.Collections.Generic.IEnumerable[System.Management.Automation.CompletionResult]] CompleteArgument(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [System.Management.Automation.Language.CommandAst] $CommandAst,
        [System.Collections.IDictionary] $FakeBoundParameters
    ) {
        $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

        $DockerNetworkParameters = @{}
        if ($FakeBoundParameters['Context']) {
            $DockerNetworkParameters['Context'] = $FakeBoundParameters['Context']
        }
        
        $networks = Get-DockerNetwork @DockerNetworkParameters

        foreach ($network in $networks) {
            $IsMatch = $false
            $RawCompletionText = ''
            switch ($ParameterName) {
                { $_ -in @('Id', 'NetworkId') } {
                    $IsMatch = $network.Id -like "$WordToComplete*"
                    $RawCompletionText = $network.Id
                }
                'Driver' {
                    $IsMatch = $network.Driver -ne 'null' -and $network.Driver -like "$WordToComplete*"
                    $RawCompletionText = $network.Driver
                }
                'Scope' {
                    $IsMatch = $network.Scope -like "$WordToComplete*"
                    $RawCompletionText = $network.Scope
                }
                default {
                    $IsMatch = $network.Name -like "$WordToComplete*"
                    $RawCompletionText = $network.Name
                }
            }
            if (!$IsMatch) {
                continue
            }

            if ($RawCompletionText -match '^[a-z0-9]+$') {
                $CompletionText = $RawCompletionText
            }
            else {
                $CompletionText = "`'$RawCompletionText`'"
            }

            $CompletionResults.Add(
                [System.Management.Automation.CompletionResult]::new(
                    $CompletionText,
                    $RawCompletionText,
                    'ParameterValue',
                    $RawCompletionText
                )
            )
        }
        
        return $CompletionResults
    }
}