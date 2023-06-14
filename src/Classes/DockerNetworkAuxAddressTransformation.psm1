using namespace System.Management.Automation
using namespace System.Collections.Generic

class DockerNetworkAuxAddressTransformation : ArgumentTransformationAttribute {
    [object] Transform([EngineIntrinsics]$engineIntrinsics, [object]$inputData) {
        $Result = [Dictionary[string, HashSet[IPAddress]]]::new([StringComparer]::OrdinalIgnoreCase)
        if ($inputData -is [object[]]) {
            foreach ($item in $inputData) {
                if ($_ -match '^(?<key>.+)=(?<value>.+)$') {
                    if (!$Result[$Matches['key']]) {
                        $Result[$Matches['key']] = @($Matches['value'])
                    }
                    else {
                        $Result[$Matches['key']].Add($Matches['value'])
                    }
                }
                else {
                    # Cannot handle the string, return the original input
                    return $inputData
                }
            }
        }
        elseif ($inputData -is [hashtable]) {
            foreach ($keyvalue in $inputData) {
                if ($result[$keyvalue.Key]) {
                    $Result[$keyvalue.Key].Add($keyvalue.Value)
                }
                else {
                    $Result[$keyvalue.Key] = @($keyvalue.Value)
                }
            }
        }
        else {
            return $inputData
        }
        return $Result
    }
}