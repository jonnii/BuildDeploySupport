Import-Module WebAdministration

function InstallAppPool() {
	param (
		[Parameter(Mandatory=$true)]
		[string]		$appPoolName, 

		[string] 		$appPoolFrameworkVersion = 'v4.0', 
		[scriptblock] 	$configure
	)

	# announce ourselves, and try to CD to IIS to make sure we have permissions
	# the web administration module installed correctly
	Write-Host "Configuring IIS"
	cd IIS:\

	Write-Host "Configuring AppPool"
	$appPool = ("IIS:\AppPools\" + $appPoolName)
	$instance = Get-Item $appPool -ErrorAction SilentlyContinue
	if (!$instance) {
	    Write-Host " -> !!!App pool does not exist, creating..." 
	    new-item $appPool
	    $instance = Get-Item $appPool
	} else {
	    Write-Host " -> App pool already exists" 
	}

	Write-Host " -> Set .NET framework version: $appPoolFrameworkVersion"
	Set-ItemProperty 	$appPool managedRuntimeVersion $appPoolFrameworkVersion

	Write-Host " -> Setting app pool properties"
	Set-ItemProperty    $appPool -name enable32BitAppOnWin64 -Value $TRUE

	Set-ItemProperty    $appPool -Name processModel.loaduserprofile -value $FALSE
	Set-ItemProperty    $appPool -Name processModel.idleTimeOut -value '20:00:00'

	Set-ItemProperty    $appPool -Name recycling.periodicRestart.time -value 0
	Clear-ItemProperty  $appPool -Name recycling.periodicRestart.schedule
	Set-ItemProperty    $appPool -Name recycling.periodicRestart.schedule -Value @{value="01:00:00"}

	if ($configure) {
		&$configure
	}

	Write-Host "Successfully configured App Pool"
}

function SetCredentials() {
	param (
		[Parameter(Mandatory=$true)] [string] $username,
		[Parameter(Mandatory=$true)] [string] $password
	)

	Write-Host "  -> Applying app pool credentials $username"
	Set-ItemProperty $appPool -Name processModel.username -value $username
	Set-ItemProperty $appPool -Name processModel.password -value $password
	Set-ItemProperty $appPool -Name processModel.identityType -value 3
}

function InstallWebSite() {
	param (
		[Parameter(Mandatory=$true)] [string] $webSiteName, 
		[Parameter(Mandatory=$true)] [string] $appPoolName, 
		[Parameter(Mandatory=$true)] [string] $url,
		$configure
	)

	# announce ourselves, and try to CD to IIS to make sure we have permissions
	# the web administration module installed correctly
	
	Write-Host "Configuring IIS"
	cd IIS:\

	Write-Host "Configuring WebSite"
	$sitePath = "IIS:\Sites\$webSiteName"
	Write-Host $sitePath
	
	# always create an http and https binding
	$bindings = @(
    	@{protocol="http";bindingInformation="*:80:$url"},
    	@{protocol="https";bindingInformation="*:443:$url"})

   	# if the site doesn't exist we should create it
	$site = Get-Item $sitePath -ErrorAction SilentlyContinue
	if (!$site) { 
	    Write-Host " -> !!! Site does not exist, creating..."
	    $id = (dir IIS:\Sites | foreach {$_.id} | sort -Descending | select -first 1) + 1
	    
	    # we set this to the web root to something
	    # if you are using octopus then it will change it later on in the deployment
	    # but we have to set it to something
	    # so use the current directory for now
	    $webRoot = (resolve-path .)
	    New-Item $sitePath -bindings $bindings -id $id -physicalPath $webRoot
	    $site = Get-Item $sitePath
	} else {
	    Write-Host " -> Site already exists..."
	}

	Write-Host " -> Configuring Bindings"
	Set-ItemProperty $sitePath -name bindings -value $bindings

	Write-Host " -> Configure App Pool"
	Set-ItemProperty $sitePath -name applicationPool -value $appPoolName

	if ($configure) {
		&$configure
	}
	
	Write-Host "Successfully configured WebSite"
}

function SetWindowsAuthentication() {
	param (
		[Parameter(Mandatory=$true)] [bool] $enabled = $TRUE
	)

	Write-Host " -> Windows authentication $enabled"
	Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/windowsAuthentication -name enabled -value $enabled -location $site.name
}

function SetAnonymousAuthentication() {
	param (
		[Parameter(Mandatory=$true)] [bool] $enabled = $TRUE
	)

	Write-Host " -> Anonymous authentication $enabled"
	Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/anonymousAuthentication -name enabled -value $enabled -location $site.name
}