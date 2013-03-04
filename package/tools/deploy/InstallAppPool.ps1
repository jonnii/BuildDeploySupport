###################################################
# DO NOT MODIFY THIS FILE, IT WILL BE OVERWRITTEN #
###################################################

# If you want to make changes please fork and contribute to the BuildDeploySupport 
# project on github, so everyone can take advantage of your changes!

# description
# -----------
# installs an app pool for sensible default settings.
# credentials are optional.

Import-Module WebAdministration

function InstallAppPool($appPoolName, $appPoolUsername, $appPoolPassword) {
	
	$appPoolFrameworkVersion = "v4.0"

	# announce ourselves, and try to CD to IIS to make sure we have permissions
	# the web administration module installed correctly
	Write-Host "Configuring IIS"
	cd IIS:\

	Write-Host "Configuring AppPool"
	$appPoolPath = ("IIS:\AppPools\" + $appPoolName)
	$pool = Get-Item $appPoolPath -ErrorAction SilentlyContinue
	if (!$pool) {
	    Write-Host " -> !!!App pool does not exist, creating..." 
	    new-item $appPoolPath
	    $pool = Get-Item $appPoolPath
	} else {
	    Write-Host " -> App pool already exists" 
	}

	Write-Host " -> Set .NET framework version: $appPoolFrameworkVersion"
	Set-ItemProperty $appPoolPath managedRuntimeVersion $appPoolFrameworkVersion

	Write-Host " -> Setting app pool properties"
	Set-ItemProperty    $appPoolPath -name enable32BitAppOnWin64 -Value $TRUE

	Set-ItemProperty    $appPoolPath -Name processModel.loaduserprofile -value $FALSE
	Set-ItemProperty    $appPoolPath -Name processModel.idleTimeOut -value '20:00:00'

	if ($appPoolUsername -and $appPoolPassword) {
	    Write-Host "  -> Applying app pool credentials $appPoolUsername"
	    Set-ItemProperty    $appPoolPath -Name processModel.username -value $appPoolUsername
	    Set-ItemProperty    $appPoolPath -Name processModel.password -value $appPoolPassword
	    Set-ItemProperty    $appPoolPath -Name processModel.identityType -value 3
	} else {
	    Write-Host "  -> ! Skipping applying app pool credentials, no username/password supplied"
	}

	Set-ItemProperty    $appPoolPath -Name recycling.periodicRestart.time -value 0
	Clear-ItemProperty  $appPoolPath -Name recycling.periodicRestart.schedule
	Set-ItemProperty    $appPoolPath -Name recycling.periodicRestart.schedule -Value @{value="01:00:00"}

	write-Host "Successfully configured App Pool"
}