function ConvertTo-AsciiDoc {
	param (
		[Parameter(Position=0,Mandatory)][string] $outputDirectory,
		[Parameter()][Alias('a')][string[]] $kramdocAttributes
	)
	$InformationPreference = 'Continue'

	Write-Information "Converting Markdown to AsciiDoc"
	Write-Information "==========================================="
	$ConvertMarkdownToAsciiDocScriptBlock = {
		param (
			[Parameter()][System.IO.FileInfo] $markdownFile,
			[Parameter()][string[]] $attributes
		)
		& {
			$relativeFilePath = Resolve-Path -Path $markdownFile.FullName -Relative
			Write-Information ("Converting " + $relativeFilePath)
			$asciiDocPath = Resolve-Path -Path $markdownFile.Directory -Relative | Join-Path -ChildPath ($markdownFile.basename + '.adoc');
			$parameters = @(
				'--wrap=none',
				'-o',
				$asciiDocPath
			)
			$attributes | ForEach-Object {
				$parameters += '-a'
				$parameters += $_
			}
			$parameters += $markdownFile.FullName

			& kramdoc $parameters
		} *>&1 | Out-Host
	}

	$jobs = @();
	Get-ChildItem -r -Path $outputDirectory -i *.md | ForEach-Object { 
		$jobs += Start-ThreadJob -ScriptBlock $ConvertMarkdownToAsciiDocScriptBlock -ThrottleLimit 10 -StreamingHost $Host -ArgumentList $_, $kramdocAttributes
	}

	if ($jobs) {
		# Wait for all to complete
		Wait-Job -Job $jobs | Out-Null
		$jobs | ForEach-Object {
			Receive-Job -Job $_
			Remove-Job -Job $_
		}		
	}
	Write-Information ""
}

Export-ModuleMember ConvertTo-AsciiDoc