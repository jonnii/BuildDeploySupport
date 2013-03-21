function Prepare-ClickOnce() {
  [CmdLetBinding()]
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
    [string] $thumbprint,
    [string] $assemblyIdentityName,
    [string] $processor = 'x86',
    [string] $magePath = "C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Bin\NETFX 4.0 Tools"
  )

  Write-Verbose "Preparing click once"
  Write-Verbose " -> Target: $target"
  Write-Verbose " -> Version: $version"
  Write-Verbose " -> Source: source"
  Write-Verbose " -> Application Executable: $applicationExecutable"
  Write-Verbose " -> Application Name: $applicationName"
  Write-Verbose " -> Application Display Name: $applicationDisplayName"
  Write-Verbose " -> Icon: $icon"
  Write-Verbose " -> Publisher: $publisher"
  Write-Verbose " -> ProviderPath: $providerPath"
  Write-Verbose " -> Thumbprint: $thumbprint"
  Write-Verbose " -> Assembly Identity Name: $assemblyIdentityName"
  Write-Verbose " -> Processor: $processor"

  # Add mage to our path
  $env:path += ";$magePath"

  Write-Verbose "Preparing install directory"
  if (test-path $target) {
    Write-Verbose "Cleaning target directory"
    rm -r -force $target > $null
  }
  mkdir $target > $null

  $targetVersion = join-path $target $version
  
  # create an install version directory
  mkdir $targetVersion
  Write-Verbose "Prepare install directory for version $version"

  cp -r -exclude *.xml "$source\*" $targetVersion
  rm "$targetVersion\*vshost*"

  Write-Verbose 'Creating manifest file'
  $manifestFileName = join-path $targetVersion "$applicationExecutable.exe.manifest"
  mage -New Application `
     -Processor $processor `
     -ToFile $manifestFileName `
     -name $applicationName `
     -Version $version `
     -FromDirectory $targetVersion `
     -IconFile $icon

  $manifestPath = resolve-path($manifestFileName)
  $doc = [xml](Get-Content -Path $manifestPath)

  # mage uses a default assembly identity name of "ApplicationName.app"
  # sometimes this can be different from the name visual studio chooses
  # so we have to reach into the manifest to update it

  if($assemblyIdentityName) {
    Write-Verbose "Applying override for  $assemblyIdentityName"
    $doc.assembly.assemblyIdentity.SetAttribute("name", $assemblyIdentityName)
    $doc.Save($manifestPath)
  }

  # $association = $doc.CreateElement('fileAssociation')
  # $association.SetAttribute('xmlns','urn:schemas-microsoft-com:clickonce.v1')
  # $association.SetAttribute('extension','.ext')
  # $association.SetAttribute('description','Decription')
  # $association.SetAttribute('progid','YourApp.Document')
  # $association.SetAttribute('defaultIcon', $icon)
  # $doc.assembly.AppendChild($association) > $null
  
  if($thumbprint -ne '')
  {
    Write-Verbose " -> signing manifest file"
    mage -Sign $manifestFileName -CertHash $thumbprint
  }
  else
  {
    Write-Verbose ' -> !!Skipping signing, no hash cert'
  }

  # rename all files to .deploy
  gci -exclude *.manifest -r $targetVersion | where { $_.PSIsContainer -eq $false } | rename-item -newname { $_.name + ".deploy" }

  Write-Verbose "creating deployment manifest"

  $applicationFileName = join-path $target "$applicationExecutable.application"
  $providerUrl = "$providerPath$applicationExecutable.application"
  
  mage -New Deployment `
    -Processor $processor `
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
  
  Write-Verbose ' -> Enabling trust url parameters'
  $doc.assembly.deployment.SetAttribute("trustURLParameters", "true")
  
  Write-Verbose ' -> Enabling map file extensions'
  $doc.assembly.deployment.SetAttribute("mapFileExtensions", "true")
  $doc.Save($fullPath)

  Write-Verbose ' -> Updating application with MinVersion'
  mage -Update $applicationFileName -MinVersion $version

  Write-Verbose ' -> Changing expiration max age => before application start up'
  $content = Get-Content $fullPath
  $content -replace "<expiration maximumAge=`"0`" unit=`"days`" />", "<beforeApplicationStartup />" | set-content $fullPath

  if($thumbprint -ne '')
  {
    Write-Verbose " -> signing .application"
    mage -Update $applicationFileName -CertHash $thumbprint
  }
  else
  {
    Write-Verbose ' -> !!Skipping signing, no hash cert'
  }

  Write-Verbose 'successfully created click once application'
}