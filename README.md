# Simpleverse.Asciidoc
Powershell module designed to help converting Markdown & Asciidoc files to other formats (PDF, Docx).

## Installation
Module is published to the Powershell Gallery https://www.powershellgallery.com/packages/Simpleverse.Bicep.

```
PS> Install-Module -Name Simpleverse.Asciidoc
```

In addition to the module you need to install the conversion engines used
* [asciidoctor](https://docs.asciidoctor.org/asciidoctor/latest/install/)
* [asciidoctor-pdf](https://docs.asciidoctor.org/pdf-converter/latest/install/)
* [kramdoc](https://github.com/asciidoctor/kramdown-asciidoc?tab=readme-ov-file#installation)
* [pandoc](https://pandoc.org/installing.html)

## Converting Asciidoc to PDF
Converts Markdown & Asciidoc files to PDF. Utilizes kramdoc to convert Markdown to AsciiDoc and the Asciidoctor-Pdf to convert to PDF.

```
PS> ConvertTo-Pdf @((Use-ConversionFolder "docs/")) -k 'title-page','icons=font','icon-set=fas','page-layout=page','toc','toclevels=2' -a 'author="Me, me@me.com"','title-page'
```

Conversion uses
* pygments as source highlighter
* asciidoctor-diagram for diagrams
* updates revdate to data of latest committed change

Parameters
* an array of folders to convert
* -k list of kramdoc attributes to be passed in
* -a list of asciidoctor attributes to be passed in

## Converting Asciidoc to Docx
Converts Markdown & Asciidoc files to Docx. Utilizes kramdoc to convert Markdown to AsciiDoc and the Asciidoctor to convert to docbook and pandoc to convert docbook to docx.

```
PS> ConvertTo-Docx docs,pages -k 'title-page','icons=font','icon-set=fas','page-layout=page','toc','toclevels=2' -a 'author="Me, me@me.com"','title-page'
```

Parameters
* an array of folders to convert
* -k list of kramdoc attributes to be passed in
* -a list of asciidoctor attributes to be passed in