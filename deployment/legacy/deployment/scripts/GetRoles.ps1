# get selective deployment roles, save to file for selective build

try
{
	$XmlPath = Resolve-Path '.\_SelectiveRoleGroupReference.xml'
	$XslPath = Resolve-Path '.\_SelectiveRoleGroupTransform.xslt'
	$OutputPath = Resolve-Path '.\_Roles.lst'
	
	$XslCTransformer = New-Object System.Xml.Xsl.XslCompiledTransform

	$XsltSetting = New-Object System.Xml.Xsl.XsltSettings
	$XsltSetting.EnableDocumentFunction = $true
	$XsltSetting.EnableScript = $false

	$XmlResolver = New-Object System.Xml.XmlUrlResolver

	$XslCTransformer.Load($XslPath, $XsltSetting, $XmlResolver)
	$XslCTransformer.Transform($XmlPath, $OutputPath)

	Write-Host "Generated output is on path: $OutputPath"
}
catch
{
	Write-Host $_.Exception -ForegroundColor Red
}