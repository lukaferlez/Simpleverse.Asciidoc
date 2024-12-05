function ConvertTo-Docx {
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
	ConvertTo-DocBook $PathSpec -o $OutputDir -k $KramdocAttributes -a $AsciidoctorAttributes

	Get-ChildItem -r -Path $OutputDir -i *.xml | ForEach-Object {
		$file=$_.directoryname+'\\'+$_.basename+'.docx';
		Push-Location $_.DirectoryName;
		pandoc -f docbook -t docx -s $_.FullName -o $file
		Pop-Location
	}

	if ($DebugPreference -eq 'SilentlyContinue') {
		Remove-Item -r -fo -i *.xml $OutputDir
	}
}

Export-ModuleMember ConvertTo-Docx
