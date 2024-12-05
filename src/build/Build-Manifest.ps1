function Build-Manifest {
	param (
		[Parameter(Mandatory = $true, Position = 0, HelpMessage = "The name of the module.")]
		[string] $name,
		[Parameter(Mandatory = $true, Position = 1, HelpMessage = "Powershell manifest path.")]
		[string] $psdPath,
		[Parameter(Mandatory = $true, Position = 2, HelpMessage = "Powershell module path.")]
		[string] $psmPath,
		[Parameter(Mandatory = $true, Position = 3, HelpMessage = "Version number.")]
		[string] $version,
		[Parameter(Mandatory = $false, HelpMessage = "Prerelease tag.")]
		[Alias("pr")]
		[string] $preReleaseTag,
		[Parameter(Mandatory = $false, HelpMessage = "Build folder.")]
		[Alias("b")]
		[string] $buildPath = './build',
		[Parameter(Mandatory = $false, HelpMessage = ".")]
		[Alias("f")]
		[string[]] $functions = @()
	)

	Write-InfoLog "Processing manifest $($psdPath)"

	$workingDir = Join-Path $buildPath $name | Resolve-Path
	Write-DebugLog "Working directory $workingDir"

	$psmPath = Resolve-Path $psmPath	
	Write-DebugLog "Module path $psmPath"

	$psdOutFile = Join-Path $workingDir "$name.psd1"
	Write-DebugLog "Manifest output path $psdOutFile"

	$modulePath = Resolve-Path $psmPath -Relative -RelativeBasePath $workingDir
	Write-DebugLog "Module path $modulePath"

	Copy-Item $psdPath $psdOutFile

	Update-ModuleManifest `
		-Path $psdOutFile `
		-ModuleVersion $version `
		-RootModule $modulePath `
		-Prerelease $preReleaseTag `
		-FunctionsToExport $functions
		
	return $psdOutFile
}