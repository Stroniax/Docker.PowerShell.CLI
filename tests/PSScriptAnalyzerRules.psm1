function New-DiagnosticRecord {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord])]
    param(
        [Parameter(Mandatory)]
        [string]
        $Message,

        [Parameter(Mandatory)]
        [System.Management.Automation.Language.IScriptExtent]
        $Extent,

        [Parameter(Mandatory)]
        [string]
        $RuleName,

        [Parameter(Mandatory)]
        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]
        $Severity,

        [Parameter()]
        [string]
        $ScriptPath,

        [Parameter(Mandatory)]
        [string]
        $RuleId,

        [Parameter()]
        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent[]]
        $SuggestedCorrections
    )
    process {
        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]::new(
            $Message,
            $Extent,
            $RuleName,
            $Severity,
            $ScriptPath,
            $SuggestedCorrections
        )
    }
}
function New-CorrectionExtent {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent])]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ViolationExtent')]
        [System.Management.Automation.Language.IScriptExtent]
        $ViolationExtent,

        [Parameter(Mandatory, ParameterSetName = 'ViolationIndex')]
        [int]
        $StartLineNumber,

        [Parameter(Mandatory, ParameterSetName = 'ViolationIndex')]
        [int]
        $EndLineNumber,
        
        [Parameter(Mandatory, ParameterSetName = 'ViolationIndex')]
        [int]
        $StartColumnNumber,
        
        [Parameter(Mandatory, ParameterSetName = 'ViolationIndex')]
        [int]
        $EndColumnNumber,

        [Parameter(Mandatory)]
        [string]
        $ReplacementText,

        [Parameter(Mandatory)]
        [string]
        $FilePath,

        [string]
        $Description
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ViolationExtent' {
                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
                    $ViolationExtent,
                    $ReplacementText,
                    $FilePath,
                    $Description
                )
            }
            'ViolationIndex' {
                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
                    $StartLineNumber,
                    $EndLineNumber,
                    $StartColumnNumber,
                    $EndColumnNumber,
                    $ReplacementText,
                    $FilePath,
                    $Description
                )
            }
            default {
                throw [NotImplementedException]"Invalid parameter set name: $($PSCmdlet.ParameterSetName)"
            }
        }
    }
}

function Get-ParameterSetName {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.HashSet[string]])]
    param(
        [Parameter()]
        [System.Management.Automation.Language.ParamBlockAst]
        $ParamBlockAst
    )
    process {
        $ParameterSetNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($ParameterAst in $ParamBlockAst.Parameters) {
            foreach ($AttributeAst in $ParameterAst.Attributes) {
                if ($AttributeAst.TypeName.GetReflectionType() -ne [Parameter]) {
                    continue
                }
                foreach ($NamedArgument in $AttributeAst.NamedArguments) {
                    if ($NamedArgument.ArgumentName -eq 'ParameterSetName') {
                        $ParameterSetNames.Add($NamedArgument.Argument.SafeGetValue())
                    }
                }
            }
        }
        $ParameterSetNames
    }
}

$script:RuleIds = @{
    'Test-ParameterAttributeMemberOrder' = 'DKR0001'
    'Test-CmdletBindingAttribute.1'      = 'DKR0002'
    'Test-CmdletBindingAttribute.2'      = 'DKR0007'
    'Test-CmdletBindingAttribute.3'      = 'DKR0008'
    'Test-OutputTypeAttribute'           = 'DKR0003'
    'Test-FunctionAliasAttribute'        = 'DKR0004'
    'Test-ParameterTypeConstraint'       = 'DKR0005'
    'Test-HasParameterAttribute'         = 'DKR0006'
    'Test-RemotingCapability.1'          = 'DKR0009'
    'Test-RemotingCapability.2'          = 'DKR0010'
    'Test-DefaultParameterSet.1'         = 'DKR0011'
    'Test-DefaultParameterSet.2'         = 'DKR0012'
}

# All [Parameter()] attributes in a param() block should reference named
# attribute properties in the same order as the other [Parameter()] attributes.
function Test-ParameterAttributeMemberOrder {

}

# [CmdletBinding()] should be the first attribute on a param() block
# DefaultParameterSetName (+)
# RemotingCapability (+)
# PositionalBinding (optional, must be $true) (-)
# SupportsShouldProcess (optional, must be $true) (-)
# ConfirmImpact (when SupportsShouldProcess is $true) (-)
function Test-CmdletBindingAttribute {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord])]
    param(
        [Parameter()]
        [System.Management.Automation.Language.ParamBlockAst]
        $ParamBlockAst
    )
    process {
        for ($CmdletBindingIndex = 0; $CmdletBindingIndex -lt $ParamBlockAst.Attributes.Count; $CmdletBindingIndex++) {
            if ($ParamBlockAst.Attributes[$CmdletBindingIndex].TypeName.GetReflectionType() -eq [CmdletBinding]) {
                break
            }
        }

        $FunctionAst = $ParamBlockAst.Parent.Parent -as [System.Management.Automation.Language.FunctionDefinitionAst]

        if ($CmdletBindingIndex -eq $ParamBlockAst.Attributes.Count) {
            # No [CmdletBinding()]
            $NewCorrectionExtent = @{
                StartLineNumber   = $ParamBlockAst.Extent.StartLineNumber
                EndLineNumber     = $ParamBlockAst.Extent.StartLineNumber
                StartColumnNumber = $ParamBlockAst.Extent.StartColumnNumber
                EndColumnNumber   = $ParamBlockAst.Extent.StartColumnNumber
                ReplacementText   = "[CmdletBinding()]$([Environment]::NewLine)`t"
                FilePath          = $ParamBlockAst.Extent.File
                Description       = 'Add [CmdletBinding()] to the param() block'
            }
            $NewDiagnosticRecord = @{
                Message              = "Function '$($FunctionAst.Name)' does not have a [CmdletBinding()] attribute"
                Extent               = $ParamBlockAst.Extent
                RuleName             = $MyInvocation.MyCommand.Name
                Severity             = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning
                ScriptPath           = $ParamBlockAst.Extent.File
                RuleId               = $script:RuleIds[$MyInvocation.MyCommand.Name + '.1']
                SuggestedCorrections = New-CorrectionExtent @NewCorrectionExtent
            }
            New-DiagnosticRecord @NewDiagnosticRecord
            return
        }

        if ($CmdletBindingIndex -ne 0) {
            # [CmdletBinding()] is not the first attribute

            $CmdletBindingAst = $ParamBlockAst.Attributes[$CmdletBindingIndex]
            $NewCorrectionExtent = @{
                ViolationExtent = $ParamBlockAst.Extent
                ReplacementText = @"
    $($CmdletBindingAttribute.Extent.Text)
    $($ParamBlockAst.Attributes.ForEach({ if ($_ -ne $CmdletBindingAst) { $_.Extent.Text } }) -join "$([Environment]::NewLine)`t")
    param(
        $($ParamBlockAst.Parameters.ForEach({ $_.Extent.Text }) -join ",$([Environment]::NewLine)$([Environment]::NewLine)`t`t")
    )
"@
                FilePath        = $ParamBlockAst.Extent.File
                Description     = 'Move [CmdletBinding()] to the first attribute on the param() block'
            }
            $NewDiagnosticRecord = @{
                Message              = "The [CmdletBinding()] attribute is not the first attribute on the param() block"
                Extent               = $CmdletBindingAst.Extent
                RuleName             = $MyInvocation.MyCommand.Name
                Severity             = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning
                ScriptPath           = $ParamBlockAst.Extent.File
                RuleId               = $script:RuleIds[$MyInvocation.MyCommand.Name + '.2']
                SuggestedCorrections = New-CorrectionExtent @NewCorrectionExtent
            }
        }
    }
}

# DefaultParameterSetName should be specified when more than one parameter set is defined
# and should be the first argument of [CmdletBinding()]
function Test-DefaultParameterSet {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord])]
    param(
        [Parameter()]
        [System.Management.Automation.Language.ParamBlockAst]
        $ParamBlockAst
    )
    process {
        $CmdletBindingAst = $ParamBlockAst.Attributes | Where-Object { $_.TypeName.GetReflectionType() -eq [CmdletBinding] }

        if (!$CmdletBindingAst) {
            return
        }

        if ($CmdletBindingAst.NamedArguments[0].ArgumentName -eq 'DefaultParameterSetName') {
            return
        }

        $ParameterSetNames = Get-ParameterSetName -ParamBlockAst $ParamBlockAst
        if ($ParameterSetNames.Count -le 1) {
            return
        }

        $DefaultParameterSetNameArgument = $CmdletBindingAst.NamedArguments | Where-Object ArgumentName -eq 'DefaultParameterSetName'

        if (!$DefaultParameterSetNameArgument) {
            # no default parameter set
            $CorrectionExtents = [object[]]::new($ParameterSetNames.Count)
            for ($i = 0; $i -lt $ParameterSetNames.Count; $i++) {
                $ParameterSetName = $ParameterSetNames[$i]
                $ReplacementText = [System.Text.StringBuilder]::new()
                [void]$ReplacementText.Append('[CmdletBinding(').AppendLine()
                [void]$ReplacementText.Append(' ', $ParamBlockAst.Extent.StartColumnNumber + 4)
                [void]$ReplacementText.Append('DefaultParameterSetName = ').Append('''')
                [void]$ReplacementText.Append($ParameterSetName).Append('''')
                foreach ($OtherNamedArgument in $CmdletBindingAst.NamedArguments) {
                    [void]$ReplacementText.AppendLine(',').Append(' ', $ParamBlockAst.Extent.StartColumnNumber + 4)
                    [void]$ReplacementText.Append($OtherNamedArgument.Extent.Text)
                }
                [void]$ReplacementText.Append(')]')
                $NewCorrectionExtent = @{
                    ViolationExtent = $CmdletBindingAst.Extent
                    ReplacementText = $ReplacementText.ToString()
                    FilePath        = $ParamBlockAst.Extent.File
                    Description     = 'Add DefaultParameterSetName to [CmdletBinding()]'
                }
                $CorrectionExtents[$i] = New-CorrectionExtent @NewCorrectionExtent
            }
            $NewDiagnosticRecord = @{
                Message              = "The [CmdletBinding()] attribute does not have a DefaultParameterSetName argument"
                Extent               = $CmdletBindingAst.Extent
                RuleName             = $MyInvocation.MyCommand.Name
                Severity             = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Error
                ScriptPath           = $CmdletBindingAst.Extent.File
                RuleId               = $script:RuleIds[$MyInvocation.MyCommand.Name + '.1']
                SuggestedCorrections = $CorrectionExtents
            }
        }
        else {
            # wrong order
            $ReplacementText = [System.Text.StringBuilder]::new()
            [void]$ReplacementText.Append('[CmdletBinding(').AppendLine().Append(' ', $ParamBlockAst.Extent.StartColumnNumber + 4)
            [void]$ReplacementText.Append($DefaultParameterSetNameArgument.Extent.Text)
            foreach ($OtherNamedArgument in $CmdletBindingAst.NamedArguments) {
                if ($OtherNamedArgument.ArgumentName -ne 'DefaultParameterSetName') {
                    [void]$ReplacementText.AppendLine(',').Append(' ', $ParamBlockAst.Extent.StartColumnNumber + 4)
                    [void]$ReplacementText.Append($OtherNamedArgument.Extent.Text)
                }
            }
            [void]$ReplacementText.Append(')]')

            $NewCorrectionExtent = @{
                ViolationExtent = $CmdletBindingAst.Extent
                ReplacementText = $ReplacementText.ToString()
                FilePath        = $ParamBlockAst.Extent.File
                Description     = 'Move DefaultParameterSetName to the first argument of [CmdletBinding()]'
            }
            $NewDiagnosticRecord = @{
                Message              = "DefaultParameterSetName should be the first argument of [CmdletBinding()]"
                Extent               = $CmdletBindingAst.Extent
                RuleName             = $MyInvocation.MyCommand.Name
                Severity             = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning
                ScriptPath           = $CmdletBindingAst.Extent.File
                RuleId               = $script:RuleIds[$MyInvocation.MyCommand.Name + '.2']
                SuggestedCorrections = New-CorrectionExtent @NewCorrectionExtent
            }
            New-DiagnosticRecord @NewDiagnosticRecord
        }
    }
}

# RemotingCapability should be specified
function Test-RemotingCapability {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord])]
    param(
        [Parameter()]
        [System.Management.Automation.Language.AttributeAst]
        $AttributeAst
    )
    process {
        if ($AttributeAst.TypeName.GetReflectionType() -ne [CmdletBinding]) {
            return
        }

        # RemotingCapability should come before SupportsShouldProcess and after DefaultParameterSetName
        $DefaultParameterSetNameIndex = -1
        $RemotingCapabilityIndex = [int]::MaxValue
        for ($i = 0; $i -lt $AttributeAst.NamedArguments.Count; $i++) {
            switch ($AttributeAst.NamedArguments[$i].ArgumentName) {
                'DefaultParameterSetName' {
                    $DefaultParameterSetNameIndex = $i
                }
                'RemotingCapability' {
                    $RemotingCapabilityIndex = $i
                }
            }
        }

        if ($RemotingCapabilityIndex -gt $DefaultParameterSetNameIndex) {
            return
        }

        # We might be able to identify the function name for the diagnostic message
        if ($AttributeAst.Parent.Parent.Parent.Parent -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
            $FunctionName = " for " + $AttributeAst.Parent.Parent.Parent.Parent.Name
        }
        else {
            $FunctionName = ''
        }

        if ($RemotingCapabilityIndex -eq -1) {
            # No RemotingCapability specified
            $RemotingCapability = [Enum]::GetValues([System.Management.Automation.RemotingCapability])
            $CorrectionExtents = [object[]]::new($RemotingCapability.Count)
            for ($i = 0; $i -lt $RemotingCapability.Count; $i++) {
                $ReplacementText = [System.Text.StringBuilder]::new()
                [void]$ReplacementText.Append('[CmdletBinding(').AppendLine().Append(' ', $AttributeAst.Extent.StartColumnNumber + 4)
                for ($e = 0; $i -le $AttributeAst.NamedArguments.Count; $e++) {
                    if ($e -gt 0) {
                        [void]$ReplacementText.Append(',').AppendLine().Append(' ', $AttributeAst.Extent.StartColumnNumber + 4)
                    }

                    if ($i -eq ($DefaultParameterSetNameIndex + 1)) {
                        [void]$ReplacementText.Append('RemotingCapability = [System.Management.Automation.RemotingCapability]::')
                        [void]$ReplacementText.Append($RemotingCapability[$i])
                    }
                    
                    if ($i -eq $AttributeAst.NamedArguments.Count) {
                        break;
                    }

                    [void]$ReplacementText.Append($AttributeAst.NamedArguments[$i].Extent.Text)
                }
                [void]$ReplacementText.Append(')]')
                $NewCorrectionExtent = @{
                    ViolationExtent = $AttributeAst.Extent
                    ReplacementText = $ReplacementText.ToString()
                    FilePath        = $AttributeAst.Extent.File
                    Description     = 'Add RemotingCapability to [CmdletBinding()]'
                }
                $CorrectionExtents[$i] = New-CorrectionExtent @NewCorrectionExtent
            }
            $NewDiagnosticRecord = @{
                Message              = "The [CmdletBinding()] attribute$FunctionName does not have a RemotingCapability argument"
                Extent               = $AttributeAst.Extent
                RuleName             = $MyInvocation.MyCommand.Name
                Severity             = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Error
                ScriptPath           = $AttributeAst.Extent.File
                RuleId               = $script:RuleIds[$MyInvocation.MyCommand.Name + '.1']
                SuggestedCorrections = $CorrectionExtents
            }
            New-DiagnosticRecord @NewDiagnosticRecord
        }
        else {
            # RemotingCapability is in the wrong place
            $ReplacementText = [System.Text.StringBuilder]::new()
            [void]$ReplacementText.Append('[CmdletBinding(').AppendLine().Append(' ', $AttributeAst.Extent.StartColumnNumber + 4)
            for ($i = 0; $i -le $AttributeAst.NamedArguments.Count; $i++) {
                
                if ($i -gt 0) {
                    [void]$ReplacementText.Append(', ').AppendLine().Append(' ', $AttributeAst.Extent.StartColumnNumber + 4)
                }

                if ($i -eq ($DefaultParameterSetNameIndex + 1)) {
                    [void]$ReplacementText.Append($AttributeAst.NamedArguments[$RemotingCapabilityIndex].Extent.Text)
                }
                
                if ($i -eq $AttributeAst.NamedArguments.Count) {
                    break;
                }

                if ($i -ne $RemotingCapabilityIndex) {
                    [void]$ReplacementText.Append($AttributeAst.NamedArguments[$i].Extent.Text)
                }
            }
            [void]$ReplacementText.Append(')]')

            $NewCorrectionExtent = @{
                ViolationExtent = $AttributeAst.Extent
                ReplacementText = $ReplacementText.ToString()
                FilePath        = $AttributeAst.Extent.File
                Description     = 'Move RemotingCapability to the correct position in [CmdletBinding()]'
            }
            $NewDiagnosticRecord = @{
                Message              = "RemotingCapability should come after DefaultParameterSetName$FunctionName"
                Extent               = $AttributeAst.Extent
                RuleName             = $MyInvocation.MyCommand.Name
                Severity             = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning
                ScriptPath           = $AttributeAst.Extent.File
                RuleId               = $script:RuleIds[$MyInvocation.MyCommand.Name + '.2']
                SuggestedCorrections = New-CorrectionExtent @NewCorrectionExtent
            }
            New-DiagnosticRecord @NewDiagnosticRecord
        }
    }
}

# The return statement should be used for flow control, not for output.
# Do not call `return $SomeValue` in a function. (In methods it is OK.)
function Test-ReturnFlowControlNotOutput {

}

# Do not use the assignment operator (=) inside an if
# condition expression. Use -eq for comparison. Assign
# prior to testing the value.
function Test-IfExpressionAssignment {

}

# [OutputType()] should be the second attribute on a param() block
# If no [OutputType()] attribute is present, the default is to
# [OutputType([System.Management.Automation.Internal.AutomationNull])]
# When present, the [OutputType()] attribute should reference the
# type of object(s) returned by the function
# The type refrerenced must be a full type name, not a name referencing
# a relative type name from a 'using namespace' statement.
# The OutputType should not be an array type.
function Test-OutputTypeAttribute {

}

# [Alias()] (when applied to a function) should come after [CmdletBinding()]
# and [OutputType()] on a param() block. Aliases should be lower-case. There
# must be at least one alias defined when the alias attribute is present. The
# alias should begin with the same text as the alias for the verb of the
# function name.
function Test-FunctionAliasAttribute {

}

# Parameters must have a type constraint
function Test-ParameterTypeConstraint {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord])]
    param(
        [Parameter()]
        [System.Management.Automation.Language.ParameterAst]
        $ParameterAst
    )
    process {
        if ($ParameterAst.StaticType -ne [object]) {
            return
        }
        $TypeConstraint = $ParameterAst.Find({ $args[0] -is [System.Management.Automation.Language.TypeConstraintAst] }, $false)
        if ($TypeConstraint) {
            return
        }

        $NewCorrectionExtent = @{
            StartLineNumber   = $ParameterAst.Extent.StartLineNumber
            EndLineNumber     = $ParameterAst.Extent.StartLineNumber
            StartColumnNumber = $ParameterAst.Extent.StartColumnNumber
            EndColumnNumber   = $ParameterAst.Extent.StartColumnNumber
            ReplacementText   = "[psobject]$([Environment]::NewLine)`t`t"
            FilePath          = $ParameterAst.Extent.File
            Description       = 'Add a type constraint to the parameter'
        }
        $NewDiagnosticRecord = @{
            Message              = "Parameter '$($ParameterAst.Name)' must have a type constraint"
            Extent               = $ParameterAst.Extent
            RuleName             = $MyInvocation.MyCommand.Name
            Severity             = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning
            ScriptPath           = $MyInvocation.MyCommand.Path
            RuleId               = $script:RuleIds[$MyInvocation.MyCommand.Name]
            SuggestedCorrections = New-CorrectionExtent @NewCorrectionExtent
        }
        New-DiagnosticRecord @NewDiagnosticRecord
    }
}

# All parameters must have a [Parameter()] attribute present
function Test-HasParameterAttribute {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord])]
    param(
        [Parameter()]
        [System.Management.Automation.Language.ParameterAst]
        $ParameterAst
    )
    process {
        $Attributes = $ParameterAst.Attributes
        foreach ($Attribute in $Attributes) {
            $AttributeType = $Attribute.TypeName.GetReflectionType()
            if ($AttributeType -eq [Parameter]) {
                return
            }
        }
        $NewCorrectionExtent = @{
            StartLineNumber   = $ParameterAst.Extent.StartLineNumber
            EndLineNumber     = $ParameterAst.Extent.StartLineNumber
            StartColumnNumber = $ParameterAst.Extent.StartColumnNumber
            EndColumnNumber   = $ParameterAst.Extent.StartColumnNumber
            ReplacementText   = "[Parameter()]$([Environment]::NewLine)`t`t"
            FilePath          = $ParameterAst.Extent.File
            Description       = 'Add a [Parameter()] attribute to the parameter'
        }
        $NewDiagnosticRecord = @{
            Message              = "Parameter '$($ParameterAst.Name)' does not have a [Parameter()] attribute"
            Extent               = $ParameterAst.Extent
            RuleName             = $MyInvocation.MyCommand.Name
            Severity             = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning
            ScriptPath           = $ParameterAst.Extent.File
            RuleId               = $script:RuleIds[$MyInvocation.MyCommand.Name]
            SuggestedCorrections = New-CorrectionExtent @NewCorrectionExtent
        }
        New-DiagnosticRecord @NewDiagnosticRecord
    }
}

# Do not use nested functions. Define functions at the top level of the script
# or module.
function Test-NestedFunction {

}

function Test-MandatoryParameterDefault {

}

Export-ModuleMember -Function 'Test-*'