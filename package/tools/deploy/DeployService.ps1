###################################################
# DO NOT MODIFY THIS FILE, IT WILL BE OVERWRITTEN #
###################################################

# If you want to make changes please fork and contribute to the BuildDeploySupport 
# project on github, so everyone can take advantage of your changes!

function InstallService($serviceName, [scriptblock]$install, [scriptblock]$configure) {
	$service = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"

	if ($service) {
		write-host "Configuring $serviceName"
		stop-service $serviceName
		&$configure
	}
	else {
		write-host "Installing $serviceName"
		&$install
	}

	start-service $serviceName
}

function InstallTopshelfService ($p, $s, $n, $e, $v) {
    $install = "$p\$s install --environment=$e"
    
    # service name is the name of the service plus the environment, seperated by a $
    # e.g. Service$Production
	$serviceName = "$n$" + $e

	InstallService $serviceName {
		invoke-expression $install
	} {
		$servicePath = "HKLM:\System\CurrentControlSet\services\$n`$$e\"
		$description = "$n $e / $v"
		$path = "`"$p\$s`" -instance:$e -displayname `"$n (Instance: $e)`" -servicename:$n"

		Set-ItemProperty -path $servicePath -name Description -value "$description"
		Set-ItemProperty -path $servicePath -name ImagePath -value "$path"
	}
}