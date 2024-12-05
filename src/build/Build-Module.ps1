using namespace System.Io

function Build-Module {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0, HelpMessage = "Files to include in the module.", ValueFromPipeline = $true)]
		[FileInfo[]] $moduleFiles,
		[Parameter(Mandatory = $true, HelpMessage = "Name of the module.")]
		[ValidateNotNullOrWhiteSpace()]
		[Alias("n")]
		[string] $name,
		[Parameter(Mandatory = $false, HelpMessage = "Build folder.")]
		[Alias("o")]
		[string] $outputPath = './build'
	)
	BEGIN
	{}
	PROCESS
	{
		Write-InfoLog "Building module $name"

		$using = @()
		$content = @()
		$functions = @()

		foreach ($file in $moduleFiles) {
			$relativeFileName = Resolve-Path $file -Relative
			if ($file.Extension -ne '.ps1' -and $file.Extension -ne '.psm1') {
				Write-InfoLog "Skipping $relativeFileName"
				continue
			}
			
			Write-InfoLog "Reading $relativeFileName"
			if ($file.Extension -eq '.ps1') {
				$results = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$null)
				if ($results.UsingStatements.Count -gt 0) {
					$results.UsingStatements | Select-Object Extent | Format-Table | Out-String | Write-DebugEx 
				}
				$fileName = Split-Path $file -LeafBase

				$using += $results.UsingStatements
				$content += "
# =========================================================
# $($fileName)
# =========================================================
				"
				$content += $results.EndBlock.Extent.Text
				$functions += $fileName
			}
			elseif ($file.Extension -eq '.psm1') {
				$content += Get-Content $file
			}
		}

		$outFile = Join-Path $outputPath "$name.psm1"
# 
		Write-DebugLog "Output file $outFile"
# 
		if (!(Test-Path $outputPath)) {
			Write-DebugLog "Creating $outputPath"
			$null = New-Item $outputPath -ItemType Directory -WhatIf:$false -Confirm:$false
		}
		elseif (Test-Path $outFile) {
			Write-DebugLog "Removing $outFile"
			Remove-Item $outFile -WhatIf:$false -Confirm:$false
		}
# 
		Write-InfoLog "Combining into $outFile"
		$using | Add-Content -Path $outFile -WhatIf:$false -Confirm:$false
		$content | Add-Content -Path $outFile -WhatIf:$false -Confirm:$false

		Resolve-Path $outFile | Write-DebugLog

		Write-InfoLog "Built module $name to $outFile"

		$module = @{}
		$module.path = $outFile
		$module.functions = $functions

		return $module
	}
	END
	{}
}