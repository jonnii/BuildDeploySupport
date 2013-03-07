function PrepareClickOnce() {
	param(
		[Parameter(Mandatory=$true)] [string] $target,
		[Parameter(Mandatory=$true)] [string] $version,
		[Parameter(Mandatory=$true)] [string] $source,
		[Parameter(Mandatory=$true)] [string] $applicationExecutable,
		[Parameter(Mandatory=$true)] [string] $applicationName,
		[Parameter(Mandatory=$true)] [string] $applicationDisplayName,
		[Parameter(Mandatory=$true)] [string] $icon,
		[Parameter(Mandatory=$true)] [string] $publisher,
		[Parameter(Mandatory=$true)] [string] $providerPath,
		[string] $thumbprint
	)

	# Add mage to our path
	$env:path += ";C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Bin\NETFX 4.0 Tools"

    write-host "Preparing install directory"
	if (test-path $target) {
		Write-Host "Cleaning target directory"
		rm -r -force $target > $null
    }
	mkdir $target > $null

	$targetVersion = join-path $target $version
	
	# create an install version directory
	mkdir $targetVersion
	write-host "Prepare install directory for version $version"

	cp -r -exclude *.xml "$source\*" $targetVersion
	rm "$targetVersion\*vshost*"

	write-host 'Creating manifest file'
	$manifestFileName = join-path $targetVersion "$applicationExecutable.exe.manifest"
	mage -New Application `
		 -Processor x86 `
		 -ToFile $manifestFileName `
		 -name $applicationName `
		 -Version $version `
		 -FromDirectory $targetVersion `
		 -IconFile $icon

	# write-host ' -> Add file associations to manfest'
	# $fullPath = resolve-path($manifestFileName)
	# $doc = [xml](Get-Content -Path $fullPath)
	# $association = $doc.CreateElement('fileAssociation')
	# $association.SetAttribute('xmlns','urn:schemas-microsoft-com:clickonce.v1')
	# $association.SetAttribute('extension','.ext')
	# $association.SetAttribute('description','Decription')
	# $association.SetAttribute('progid','YourApp.Document')
	# $association.SetAttribute('defaultIcon', $icon)
	# $doc.assembly.AppendChild($association) > $null
	# $doc.Save($fullPath)

	if($thumbprint -ne '')
	{
		write-host " -> signing manifest file"
		mage -Sign $manifestFileName -CertHash $thumbprint
	}
	else
	{
		write-host ' -> !!Skipping signing, no hash cert'
	}

	# rename all files to .deploy
	gci -exclude *.manifest -r $targetVersion | where { $_.PSIsContainer -eq $false } | rename-item -newname { $_.name + ".deploy" }

	write-host "creating deployment manifest"

	$applicationFileName = join-path $target "$applicationExecutable.application"
	$providerUrl = join-path $providerPath "$applicationExecutable.application"
    mage -New Deployment `
		 -Processor x86 `
		 -Install true `
		 -Publisher $publisher `
		 -ProviderUrl $providerUrl `
		 -AppManifest $manifestFileName `
		 -Version $version `
		 -Name $applicationDisplayName `
		 -ToFile $applicationFileName `
		 -UseManifestForTrust true

	$fullPath = resolve-path($applicationFileName)
	$doc = [xml](Get-Content -Path $fullPath)
	
	write-host ' -> Enabling trust url parameters'
	$doc.assembly.deployment.SetAttribute("trustURLParameters", "true")
	
	write-host ' -> Enabling map file extensions'
	$doc.assembly.deployment.SetAttribute("mapFileExtensions", "true")
	$doc.Save($fullPath)

	write-host ' -> Updating application with MinVersion'
	mage -Update $applicationFileName -MinVersion $version

	write-host ' -> Changing expiration max age => before application start up'
	$content = Get-Content $fullPath
	$content -replace "<expiration maximumAge=`"0`" unit=`"days`" />", "<beforeApplicationStartup />" | set-content $fullPath

	if($thumbprint -ne '')
	{
		write-host " -> signing .application"
		mage -Update $applicationFileName -CertHash $thumbprint
	}
	else
	{
		write-host ' -> !!Skipping signing, no hash cert'
	}

	write-host 'successfully created click once application'
}