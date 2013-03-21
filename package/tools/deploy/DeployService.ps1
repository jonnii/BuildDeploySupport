function Install-Service() {
  [CmdLetBinding()]
  param (
    [Parameter(Mandatory=$true)] [string]       $serviceName, 
    [Parameter(Mandatory=$true)] [scriptblock]  $install, 
    [Parameter(Mandatory=$true)] [scriptblock]  $configure
  )

  $service = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"

  if ($service) {
    Write-Verbose "Stopping $serviceName"
    Stop-Service $serviceName
    
    Write-Verbose " -> Configuring $serviceName"
    &$configure
  }
  else {
    Write-Verbose "Installing $serviceName"
    &$install
  }

  Write-Verbose "Starting $serviceName"
  Start-Service $serviceName
}

function Install-TopshelfService() {
  param (
    [Parameter(Mandatory=$true)] [string] $path,
    [Parameter(Mandatory=$true)] [string] $environment,
    [Parameter(Mandatory=$true)] [string] $version,
    [Parameter(Mandatory=$true)] [string] $executable,
    [Parameter(Mandatory=$true)] [string] $name,
    [string] $commandLineArguments
  )

  Write-Verbose " => Installing Topshelf Service"
  Write-Verbose "   -> Path: $path"
  Write-Verbose "   -> Environment: $environment"
  Write-Verbose "   -> Version: $version"
  Write-Verbose "   -> Executable: $executable"
  Write-Verbose "   -> Name: $name"
  Write-Verbose "   -> CommandLineArguments: $commandLineArguments"

  # sanitize the environment name by removing spaces
  $environment = $environment.replace(' ','')

  # service name is the name of the service plus the environment, seperated by a $
  # e.g. Service$Production
  
  function Install-FirstTime() {
    [CmdletBinding()] param()

    $command = "& '$path\$executable' install -servicename:$name -instance:$environment $commandLineArguments"
    Write-Verbose " => Executing: $command"
    Invoke-Expression $command
  }

  function Update-ServiceProperties() {
    [CmdletBinding()] param()
    # updates service properties using the registry
    # this could use sc.exe

    $registryPath = "HKLM:\System\CurrentControlSet\services\$name`$$environment\"
    $serviceDescription = "$name $environment / $version"
    $servicePath = "`"$path\$executable`" -instance `"$environment`" -displayname `"$name (Instance: $environment)`" -servicename `"$name`""

    Write-Verbose " => Updating path: $registryPath"
    Write-Verbose "   -> Description: $serviceDescription"
    Write-Verbose "   -> ImagePath: $servicePath"

    Set-ItemProperty -path $registryPath -name Description -value "$serviceDescription"
    Set-ItemProperty -path $registryPath -name ImagePath -value "$servicePath"
  }

  Install-Service "$name`$$environment" `
    -install ${function:Install-FirstTime} `
    -configure ${function:Update-ServiceProperties}
}