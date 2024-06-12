
param (
    [Parameter(Mandatory=$true, 
    HelpMessage="The name of the resource group containing the target app.")]
    [string]
    $resourceGroup,
    [Parameter(Mandatory=$true,
    HelpMessage="The name of the target app.")]
    [string]
    $webAppName,
    [Parameter(Mandatory=$false,
    HelpMessage="The name of the slot to target. If not supplied, will target the production slot.")]
    [string]
    $slotName,
    [Parameter(Mandatory=$true,
    HelpMessage="Array of app config entries in the format [Name]=[Value]. Example: @('TestSetting=Value1', 'TestSetting2=Value2').")]
    [string[]]
    $appConfigEntries
)



if($slotName){
    $webApp = Get-AzWebAppSlot -ResourceGroupName $resourceGroup -Name $webAppName -Slot $slotName
}
else
{
    $webApp = Get-AzWebApp -ResourceGroupName $resourceGroup -Name $webAppName 
}

$hasUpdatedValues = $false
#Get Current settings. 
$currentSlotSettings = Get-AzWebAppSlotConfigName -ResourceGroupName $resourceGroup -Name $webAppName

Write-Output "$($currentSlotSettings.AppSettingNames.Count) AppSettings currently marked as Slot Settings."

$configEntries = new-object System.Collections.Hashtable
foreach ($setting in $webApp.SiteConfig.AppSettings){
    Write-Output "Adding $($setting.Name) as current slot setting"
    $configEntries.Add($setting.Name, $setting.Value)
}
$slotSettings = new-object System.Collections.Hashtable
foreach($entry in $appConfigEntries){
    $configValues = $entry -split '='
    $key = $configValues[0]
    $value = $configValues[1]
    Write-Output "Adding $key with value $value"
    $slotSettings.Add($key, $value)
}


foreach($slotSetting in $slotSettings.Keys){
    $slotValue = $slotSettings[$slotSetting]

    if(-not ($configEntries.ContainsKey($slotSetting)) -or 
        ($configEntries[$slotSetting] -ne $slotValue) -or 
        -not ($null -ne $currentSlotSettiongs.AppSettingsNames -and ($currentSlotSettings.AppSettingsNames.Contains($slotSetting))))
    {
        Write-Output "Updating $slotSetting to value $slotValue from " $configEntries[$slotSetting]
        $configEntries[$slotSetting] = $slotValue
        $hasUpdatedValues = $true   
    }
    
}


if($hasUpdatedValues){
    Write-Output 'Updating values for web site.'
    if($slotName){
        
        $_= Set-AzWebAppSlot -ResourceGroupName $resourceGroup -Name $webAppName -Slot $slotName -AppSettings $configEntries
    }
    else{
        $_ = Set-AzWebApp -ResourceGroupName $resourceGroup -Name $webAppName -AppSettings $configEntries
    }
    Write-Output "Setting App Slot config names for $webAppName to $( $slotSettings.Keys -join ',')"
    Set-AzWebAppSlotConfigName -AppSettingNames $slotSettings.Keys -ResourceGroupName $resourceGroup  -Name $webAppName
}
else{
    Write-Output 'No values are changed; not updating values for site.'
}
