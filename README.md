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

    # prepare a click once installer from a directory
    PrepareClickOnce `
        '..\installers' `                   # output directory for the package
        '1.2.3.4' `                         # version of the installer
        '..\bin\Release' `                  # directory to clickonce-ify                     
        'MyApplication.exe' `               # application executable
        'MyCompanyAwesomeApp' `             # your application identity name
        'My Awesome Application' `          # the display name for the application
        'icon.png' `                        # your app icon
        'my company' `                      # the company publishing
        'http://mycompany.com/downloads/' ` # the download location for the installer
        'my-certificate-thumbprint'         # a certificate thumbprint to sign the package with (optional)
