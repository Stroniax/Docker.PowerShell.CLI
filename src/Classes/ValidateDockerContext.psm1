using namespace System.Collections;
using namespace System.Diagnostics;
using namespace System.Collections.Generic;
using namespace System.Management.Automation;
using namespace System.Management.Automation.Language;

class ValidateDockerContext : ValidateArgumentsAttribute {
    [void ]Validate([object]$Context, [EngineIntrinsics]$EngineIntrinsics) {
        if ($Context -as [string]) {
            Write-Debug 'docker context list --quiet'
            $Contexts = docker context list --quiet
            if ($Contexts -notcontains $Context) {
                throw "Context '$Context' does not exist"
            }
        }
    }
}
