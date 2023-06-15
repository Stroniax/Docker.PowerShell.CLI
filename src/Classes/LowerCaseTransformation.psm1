using namespace System.Management.Automation

class LowerCaseTransformation : ArgumentTransformationAttribute {
    [Object] Transform([EngineIntrinsics]$engineIntrinsics, [System.Object]$inputData) {

        $result = foreach ($item in $inputData) {
            ([string]$item).ToLower()
        }

        return $result
    }
}