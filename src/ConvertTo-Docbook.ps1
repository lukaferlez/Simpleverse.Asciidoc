function ConvertTo-DocBook {
	Param(
		[Parameter(Mandatory = $true, Position = 0, HelpMessage = "PathSpec to grep files to convert.")]
		[ValidateNotNullOrWhiteSpace()]
		[string[]] $PathSpec,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrWhiteSpace()]
		[Alias('o')]
		[string] $OutputDir = './.build/docx',
		[Parameter(Mandatory = $false)]
		[Alias('k')]
		[string[]] $KramdocAttributes,
		[Parameter(Mandatory = $false)]
		[Alias('a')]
		[string[]] $AsciidoctorAttributes
	)

	if (Test-Path $OutputDir) {
		Remove-Item -r -fo $OutputDir
	}
	$null = New-Item $OutputDir -ItemType Directory

	Copy-Item $PathSpec -Destination $OutputDir -Force -Recurse

	ConvertTo-AsciiDoc $OutputDir -a $KramdocAttributes

	$parameters = @(
		'-b', 'docbook',
		'-r', 'asciidoctor-diagram',
		'-a', 'source-highlighter=pygments',
		'-a', 'compress',
		'-a', "revdate=$date"
	)
	$AsciidoctorAttributes | ForEach-Object {
		$parameters += '-a'
		$parameters += $_
	}
	$parameters += "'$($OutputDir)/**/*.adoc'"

	& asciidoctor @parameters

	if ($DebugPreference -eq 'SilentlyContinue') {
		Remove-Item -r -fo -i *.adoc,*.md $OutputDir
	}
}

Export-ModuleMember ConvertTo-DocBook