class ConversionFolderInfo {
	# Optionally, add attributes to prevent invalid values
	[ValidateNotNullOrEmpty()][string]$SourcePath
	[ValidateNotNullOrEmpty()][string]$TargetPath

	ConversionFolderInfo([string] $path) {
		$this.Init($path, $path)
	}

	ConversionFolderInfo(
		[string] $SourcePath,
		[string] $TargetPath
	) {
		$this.Init($SourcePath, $TargetPath)
	}

	hidden Init([string] $SourcePath, [string] $TargetPath) {
		$this.SourcePath = $SourcePath
		$this.TargetPath = $TargetPath
	}
}

function Use-ConversionFolder {
	param (
		[Parameter(Position=0,Mandatory)] [string] $source,
		[Parameter(Position=1)] [string] $target
	)

	if (!$target) {
		$target = $source
	}

	return [ConversionFolderInfo]::new($source, $target)
}

Export-ModuleMember Use-ConversionFolder