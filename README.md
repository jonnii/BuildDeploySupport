BuildDeploySupport
==================

BuildDeploySupport is a collection of useful build scripts that you can use in your own project. When
you install the package it will create a ./Deploy/Support directory at the same level as your
solution and create a solution folder in your project so you can browse the scripts.

You can then use the scripts to simplify your deployment!

Please note that this is a work in progress. 

How do I get it?
----------------
    
    # to install
	install-package BuildDeploySupport

    # to upgrade
    update-package BuildDeploySupport 

How do I use it?
----------------

    . .\DeployWeb.ps1

    # install your app pool
    InstallAppPool 'my-app-pool' -configure {
        SetCredentials 'username' 'password'
    }

    # install your website
    InstallWebSite $OctopusWebSiteName 'my-app-pool' 'www.yourdomain.com' {
    	SetWindowsAuthentication $true
    	SetAnonymousAuthentication $false	
    }

    . .\DeployService.ps1

    # install a topshelf service
    InstallTopshelfService `
        $OctopusOriginalPackageDirectoryPath `
        $OctopusEnvironmentName `
        $OctopusPackageVersion `
        'startup.exe' `
        'Billion Dollar Idea'

    # install another service
    InstallService $serviceName `
        -install {
            # install my service
        } `
        -configure {
            # configure my service
        }