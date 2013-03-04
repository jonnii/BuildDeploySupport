###################################################
# DO NOT MODIFY THIS FILE, IT WILL BE OVERWRITTEN #
###################################################

# If you want to make changes please fork and contribute to the BuildDeploySupport 
# project on github, so everyone can take advantage of your changes!

# description
# -----------
# creates a website in IIS with authentication and bindings configured. 
# by convention SSL bindings will always be created, anonymous authentication
# will be disabled and windows authentication will be enabled

Import-Module WebAdministration

function InstallWebSite($webSiteName, $appPoolName, $subdomain, $domain) {
	
	# announce ourselves, and try to CD to IIS to make sure we have permissions
	# the web administration module installed correctly
	
	Write-Host "Configuring IIS"
	cd IIS:\

	Write-Host "Configuring WebSite"
	$sitePath = "IIS:\Sites\$webSiteName"
	Write-Host $sitePath
	
	# always create an http and https binding
	$bindings = @(
    	@{protocol="http";bindingInformation="*:80:$subdomain.$domain"},
    	@{protocol="https";bindingInformation="*:443:$subdomain.$domain"})

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

	Write-Host " -> Configure App Pool"
	Set-ItemProperty $sitePath -name applicationPool -value $appPoolName

	Write-Host " -> Configuring Bindings"
	Set-ItemProperty $sitePath -name bindings -value $bindings

	Write-Host " -> Configure Authentication"
	Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/anonymousAuthentication -name enabled -value false -location $site.name
	Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/windowsAuthentication -name enabled -value true -location $site.name

	Write-Host "Successfully configured WebSite"
}