class ConversionFileInfo
{
	# Optionally, add attributes to prevent invalid values
	[ValidateNotNullOrEmpty()][ConversionFolderInfo] $FolderInfo
	[ValidateNotNullOrEmpty()][string]$SourcePath
	[ValidateNotNullOrEmpty()][string]$TargetPath
	[string]$ChangeDate

	ConversionFolderInfo(
		[ConversionFolderInfo] $FolderInfo,
		[string] $SourcePath,
		[string] $ChangeDate,
		[string] $TargetPath
	) {
		$this.FolderInfo = $FolderInfo
		$this.SourcePath = $SourcePath
		$this.ChangeDate = $ChangeDate
		$this.TargetPath = $TargetPath
	}
}

function collectFileInformation {
	Param(
		[Parameter(Position=0,Mandatory)][ConversionFolderInfo[]] $folders,
		[Parameter(Position=1,Mandatory)][string] $outputDirectory,
		[Parameter(Mandatory=$false)][Alias('vf')][string] $versionFormat
	)
	$InformationPreference = 'Continue'
	
	Write-Information "Collecting file information"
	Write-Information "==========================================="

	$filesToProcess = $folders | ForEach-Object {
		$folderInfo = $_;
		Push-Location $folderInfo.SourcePath
		Write-Information (Get-Location | Out-String)
		Get-ChildItem -r -i *.adoc,*.md | ForEach-Object { 
			if ($null -ne $versionFormat -and $versionFormat -ne "") {
				$date = git log -1 --format="%cE, %ai" $_.FullName;
				if (!$date) {
					$date = "unoffical"
				}	
			}
			
			$relativePath = Resolve-Path -Path $_.FullName -Relative | Split-Path -Parent
			$targetPath = Join-Path $outputDirectory -ChildPath ($folderInfo.TargetPath) | Join-Path -ChildPath $relativePath | Join-Path -ChildPath ($_.BaseName+'.adoc')
			[ConversionFileInfo]@{ FolderInfo = $folderInfo; SourcePath = $_; ChangeDate = $date; TargetPath = $targetPath; }
		}
		Pop-Location
	}
	Write-Information ($filesToProcess | Out-String)
	Write-Information ""
	return $filesToProcess
}

function convertAsciiDocToPdf {
	param (
		[Parameter(Position=0,Mandatory)] [ConversionFileInfo[]] $filesToProcess,
		[Parameter()][Alias('a')][string[]] $asciidoctorAttributes
	)
	$InformationPreference = 'Continue'
	
	Write-Information "Converting AsciiDoc to PDF"
	Write-Information "==========================================="
	$ConvertAsciiDocToPdfScriptBlock = {
		param (
			[Object] $fileToConvert,
			[string[]] $attributes
		)
		& {			
			$file = $fileToConvert.TargetPath;
			$date = $fileToConvert.ChangeDate;
			Write-Information ("Converting " + $file)

			$parameters = @(
				'-r', 'asciidoctor-diagram',
				'-a', 'source-highlighter=pygments',
				'-a', 'compress',
				'-a', "revdate=$date"
			)
			$attributes | ForEach-Object {
				$parameters += '-a'
				$parameters += $_
			}
			$parameters += $file

			& asciidoctor-pdf $parameters
		} *>&1 | Out-Host
	}

	$jobs = @();
	$filesToProcess | ForEach-Object {
		$jobs += Start-ThreadJob -ScriptBlock $ConvertAsciiDocToPdfScriptBlock -ThrottleLimit 10 -StreamingHost $Host -ArgumentList $_, $asciidoctorAttributes
	}

	# Wait for all to complete
	if ($jobs) {
		Wait-Job -Job $jobs | Out-Null
		$jobs | foreach {
			Receive-Job -Job $_
			Remove-Job -Job $_
		}
	}

	Write-Information ""
}

function ConvertTo-Pdf {
	param (
		[Parameter(Position=0,Mandatory)] [ConversionFolderInfo[]] $sources,
		[Parameter(Mandatory=$false)] [Alias('o')] [string] $outputDirectory = './.build/pdf',
		[Parameter(Mandatory=$false)] [Alias('k')] [string[]] $kramdocAttributes,
		[Parameter(Mandatory=$false)] [Alias('a')] [string[]] $asciidoctorAttributes,
		[Parameter(Mandatory=$false)] [Alias('vf')] [string] $versionFormat = "%cE, %ai",
		[Parameter(Mandatory=$false)] [Alias('c')] [switch] $outputDirectoryCreated
	)
	$InformationPreference = 'Continue'

	Write-Information "Start build PDF"
	Write-Information "==========================================="
	Write-Information ""

# 	Write-Information "Checking for ThreadJob module"
# 	Write-Information "==========================================="
# 	if (Get-Module -ListAvailable -Name "Microsoft.PowerShell.ThreadJob") {
# 		Write-Information "ThreadJob module exists"
# 	}
# 	else {
# 		Write-Information "ThreadJob module doesn't exist, installing."
# 		Install-Module -Name Microsoft.PowerShell.ThreadJob -Scope CurrentUser -Force
# 		Write-Information "ThreadJob module installed."
# 	}
# 	Write-Information ""

	if ($outputDirectoryCreated -eq $false) {
		if (Test-Path $outputDirectory) {
			Remove-Item -r -fo $outputDirectory
		}
		$null = New-Item $outputDirectory -ItemType Directory
	}

	Write-Information "Copy source to output"
	Write-Information "==========================================="
	$sources | ForEach-Object {
		Copy-Item $_.SourcePath -Destination (Join-Path $outputDirectory $_.TargetPath) -Force -Recurse
	}
	Write-Information ""

	Write-Information "Execute conversion"
	Write-Information "==========================================="
	$filesToProcess = collectFileInformation $sources $outputDirectory -vf $versionFormat
	ConvertTo-AsciiDoc $outputDirectory -a $kramdocAttributes
	convertAsciiDocToPdf $filesToProcess -a $asciidoctorAttributes
	Write-Information ""

	Write-Information "Cleaning up"
	Write-Information "==========================================="
	Remove-Item $outputDirectory -i @("*.adoc", "*.md", "diag-*.*") -Recurse -Force
	Write-Information ""

	Write-Information "End build PDF"
	Write-Information ""
}

Export-ModuleMember ConvertTo-Pdf