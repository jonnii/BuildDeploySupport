BuildDeploySupport
==================

BuildDeploySupport is a collection of useful build scripts that you can use in your own project. 

How do I get it?
----------------

	install-package BuildDeploySupport

How do I use it?

    . .\DeployWeb.ps1

    InstallAppPool 'my-app-pool' 'v4.0' {
    	SetCredentials 'username' 'password'
    }

    InstallWebSite $OctopusWebSiteName 'my-app-pool' 'www.yourdomain.com' {
    	SetWindowsAuthentication $true
    	SetAnonymousAuthentication $false	
    }

    . .\DeployService.ps1

    InstallService 'servicename' {
        # first time service install
        invoke-expression 'your.exe install'
    } {
        # subsequent service configure
    }
