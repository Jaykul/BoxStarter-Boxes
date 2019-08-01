filter RemoveAppX {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		[string]$appName
	)
	Write-Information "Trying to remove $appName" -InformationAction Continue
	Get-AppxPackage $appName -AllUsers | Remove-AppxPackage
	Get-AppXProvisionedPackage -Online | Where DisplayName -like $appName | Remove-AppxProvisionedPackage -Online
}

filter InstallCodeExtension {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		[string]$extension
	)
	Write-Information "Install extension $extension" -InformationAction Continue
    if (Get-Command code -ErrorAction Ignore) {
        code --install-extension $extension
    }
    if (Get-Command code-insiders -ErrorAction Ignore) {
        code-insiders --install-extension $extension
    }
}

filter UpdateModule {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		[string]$module
    )
    Find-Module $module | Where-Object {
        -not ( Get-Module -FullyQualifiedName @{ ModuleName = $_.Name; ModuleVersion = $_.Version } -ListAvailable )
    } | Install-Module -SkipPublisherCheck -AllowClobber -RequiredVersion { $_.Version }
}
