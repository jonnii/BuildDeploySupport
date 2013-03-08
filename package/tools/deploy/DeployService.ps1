function InstallService() {
	param (
		[Parameter(Mandatory=$true)] [string] 		$serviceName, 
		[Parameter(Mandatory=$true)] [scriptblock] 	$install, 
		[Parameter(Mandatory=$true)] [scriptblock] 	$configure
	)

	$service = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"

	if ($service) {
		write-host "Stopping $serviceName"
		stop-service $serviceName
		
		write-host " -> Configuring $serviceName"
		&$configure
		
	}
	else {
		write-host "Installing $serviceName"
		&$install
	}

	write-host "Starting $serviceName"
	start-service $serviceName
}

function InstallTopshelfService() {
    param (
    	[Parameter(Mandatory=$true)] [string] $path,
    	[Parameter(Mandatory=$true)] [string] $environment,
    	[Parameter(Mandatory=$true)] [string] $version,
    	[Parameter(Mandatory=$true)] [string] $executable,
    	[Parameter(Mandatory=$true)] [string] $name
    )

    # service name is the name of the service plus the environment, seperated by a $
    # e.g. Service$Production
	$serviceName = "$name$" + $environment

	function InitialInstall() {
		iex "& '$path\$executable' install --environment=$environment"
	}

	function UpdateServiceProperties() {
		# updates service properties using the registry
		# this could use sc.exe

		$registryPath = "HKLM:\System\CurrentControlSet\services\$name`$$environment\"
		$serviceDescription = "$name $environment / $version"
		$servicePath = "`"$path\$executable`" -instance:$environment -displayname `"$name (Instance: $environment)`" -servicename:$name"

		Set-ItemProperty -path $registryPath -name Description -value "$serviceDescription"
		Set-ItemProperty -path $registryPath -name ImagePath -value "$servicePath"
	}

	InstallService $serviceName `
		-install ${function:InitialInstall} `
		-configure ${function:UpdateServiceProperties}
}