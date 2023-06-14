using namespace System.Collections;
using namespace System.Diagnostics;
using namespace System.Collections.Generic;
using namespace System.Management.Automation;
using namespace System.Management.Automation.Language;

class DockerBuildAddHostTransformation : ArgumentTransformationAttribute {
    [object] Transform([EngineIntrinsics]$EngineIntrinsics, [object]$InputData) {
        if ($InputData -as [Dictionary[string, ipaddress]]) {
            return $InputData
        }

        $Dictionary = [Dictionary[string, IPAddress]]::new()
        # InputData may be a hasthable of valid dns name to IP address
        if ($InputData -is [hashtable]) {
            foreach ($Key in $InputData.Keys) {
                $Dictionary[$Key] = [ipaddress]$InputData[$Key]
            }
        }
        else {
            foreach ($Item in $InputData) {
                if ($Item -is [string]) {
                    $Parts = $Item.Split(':')
                    if ($Parts.Length -ne 2) {
                        throw "Invalid host specification '$Item'. Input must be in the form 'hostname:ipaddress'."
                    }
                    $Dictionary[$Parts[0]] = [ipaddress]$Parts[1]
                }
                else {
                    try {
                        $Dictionary.Add($Item)
                    }
                    catch {
                        throw [ArgumentException]::new("Invalid host specification '$Item'. Input must be in the form 'hostname:ipaddress'.", $_.Exception)
                    }
                }
            }
        }
        return $Dictionary
    }
}
