param(
	[Parameter(Mandatory=$true, Position=0, HelpMessage="Module version.")]
	[Alias("v")]
	[string] $version,
	[Parameter(Mandatory=$false, Position=1, HelpMessage="The API key to use when publishing.")]
	[Alias("ak")]
	[string] $apiKey,
	[Parameter(Mandatory=$false, HelpMessage="Force publish without confirmation.")]
	[Alias("f")]
	[switch] $Force
)

. "src/build/Build-Module.ps1"
. "src/build/Build-Manifest.ps1"
. "src/build/Publish-Manifest.ps1"

$moduleName = 'Simpleverse.AsciiDoc'
$sourceDir = './src'
$outputDir = "./build/$($moduleName)"

task clean {
	if (Test-Path $outputDir) {
		Remove-Item -Recurse -Force $outputDir
	}
}

task build clean,{
	Import-Module PoShLog
	Start-Logger -Console

	$moduleFiles = Get-ChildItem "$($sourceDir)/*.ps1" | Resolve-Path -Relative

	Write-InfoLog "Analyzing script files"
	foreach ($moduleFile in $moduleFiles) {
		Write-InfoLog "Analyzing $moduleFile"
		Invoke-ScriptAnalyzer $moduleFile -WhatIf:$false -Confirm:$false
	}

	$module = ,$moduleFiles | Build-Module -n $moduleName -o $outputDir

	Write-InfoLog $module

	Build-Manifest $moduleName "$($sourceDir)/manifest.psd1" $module.path $version -f $module.functions

	Close-Logger
}

task publish build,{
	Import-Module PoShLog
	Start-Logger -Console

	"$($outputDir)/$($moduleName).psd1" | Publish-Manifest -ak $apiKey -f:$Force -WhatIf:$WhatIfPreference

	Close-Logger
}

task import build,{
	if (Get-Module -ListAvailable -Name $moduleName) {
		Remove-Module Simpleverse.AsciiDoc
	}
	Import-Module "$($outputDir)/$($moduleName).psd1"
}

task . build