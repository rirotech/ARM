param (
    
    [Parameter(Mandatory=$true, HelpMessage="The output from the ARM/Bicep template.")]
    [string]
    $armOutputString, 
    [Parameter(HelpMessage="A prefix to use for the generated properties in addition to the name of the output variable.")]
    [string]
    $propertyPrefix, 
    [Parameter(HelpMessage="Separate for array values. Default is semi-colon.")]
    [string]
    $arraySeparator = ";"
)



$armOutputObj = $armOutputString | convertfrom-json

$armOutputObj.PSObject.Properties | ForEach-Object {
    $type = ($_.value.type).ToLower()
    $key = $_.name
    $value = $_.value.value
    $propName = $key 
    if(![string]::IsNullOrWhiteSpace($propertyPrefix)){
        $propName = $propertyPrefix + $key 
    }
    
    if ($type -eq "securestring") {
        Write-Host "##vso[task.setvariable variable=$propName;issecret=true]$value"
        Write-Host "Create variable with key '$propName' and value <<SECRET>> of type '$type'"
    } elseif ($type -eq "string") {
        Write-Host "##vso[task.setvariable variable=$propName]$value"
        Write-Host "Create variable with key '$propName' and value '$value' of type '$type'"
    } elseif ($type -eq "array"){
        Write-Host "Detected variable array: " $propName " with " $value.length " values"
        $arrayValues = $value -Join $arraySeparator
        #Write array of values  
        Write-Host "##vso[task.setvariable variable=$propName]$arrayValues"
        Write-Host "Created array variable with key '$propName' and value '$arrayValues'"
    } else {
        Throw "Type '$type' not supported!"
    }
}