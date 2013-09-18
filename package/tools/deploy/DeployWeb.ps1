Import-Module WebAdministration

function Install-AppPool() {
  <#
  .DESCRIPTION
  Installs an AppPool.

  .PARAMETER appPoolName
  The name of the AppPool.

  .PARAMETER appPoolFrameworkVersion
  The version of the .NET Framework to use for this AppPool, defaults to .net v4.0.

  .PARAMETER configure
  A script block to call when configuring the AppPool.

  .EXAMPLE
  Install-AppPool "MyApplication-AppPool" -configure { ... configure ... }
  #>

  [CmdLetBinding()]
  param (
    [Parameter(Mandatory=$true)] [string]    $appPoolName, 
    [string]        $appPoolFrameworkVersion = 'v4.0', 
    [scriptblock]   $configure
  )

  # announce ourselves, and try to CD to IIS to make sure we have permissions
  # the web administration module installed correctly
  Write-Verbose "Configuring IIS"
  cd IIS:\

  Write-Verbose "Configuring AppPool"
  $appPool = ("IIS:\AppPools\" + $appPoolName)
  $instance = Get-Item $appPool -ErrorAction SilentlyContinue
  if (!$instance) {
      Write-Verbose " -> !!!App pool does not exist, creating..." 
      new-item $appPool
      $instance = Get-Item $appPool
  } else {
      Write-Verbose " -> App pool already exists" 
  }

  Write-Verbose " -> Set .NET framework version: $appPoolFrameworkVersion"
  Set-ItemProperty  $appPool managedRuntimeVersion $appPoolFrameworkVersion

  Write-Verbose " -> Setting app pool properties"
  Set-ItemProperty    $appPool -name enable32BitAppOnWin64 -Value $TRUE

  Set-ItemProperty    $appPool -Name processModel.loaduserprofile -value $FALSE
  Set-ItemProperty    $appPool -Name processModel.idleTimeOut -value '20:00:00'

  Set-ItemProperty    $appPool -Name recycling.periodicRestart.time -value 0
  Clear-ItemProperty  $appPool -Name recycling.periodicRestart.schedule
  Set-ItemProperty    $appPool -Name recycling.periodicRestart.schedule -Value @{value="01:00:00"}

  if ($configure) {
    &$configure
  }

  Write-Verbose "Successfully configured App Pool"
}

function Set-Credentials() {
  <#
  .DESCRIPTION
  Sets the credentails that an AppPool runs as

  .EXAMPLE
  Set-Credentails 'username' 'password'
  #>

  [CmdLetBinding()]
  param (
    [Parameter(Mandatory=$true)] [string] $username,
    [Parameter(Mandatory=$true)] [string] $password
  )

  Write-Verbose "  -> Applying app pool credentials $username"
  Set-ItemProperty $appPool -Name processModel.userName -value $username
  Set-ItemProperty $appPool -Name processModel.password -value $password
  Set-ItemProperty $appPool -Name processModel.identityType -value 3
}

function Install-WebSite() {
  <#
  .DESCRIPTION
  Installs an WebSite.

  .PARAMETER webSiteName
  The name of the website.

  .PARAMETER appPoolName
  The name of the AppPool to use for this website.

  .PARAMETER url
  The url of this website, which will be used when setting up bindings.

  .PARAMETER configure
  A script block to call when configuring the website.

  .EXAMPLE
  Install-WebSite "MyWebSite" "MyWebSite-AppPool" "http://example.com" -configure { ... configure ... }
  #>

  [CmdLetBinding()]
  param (
    [Parameter(Mandatory=$true)] [string] $webSiteName, 
    [Parameter(Mandatory=$true)] [string] $appPoolName, 
    [Parameter(Mandatory=$true)] [string] $url,
    [scriptblock] $configure
  )

  # announce ourselves, and try to CD to IIS to make sure we have permissions
  # the web administration module installed correctly
  
  Write-Verbose "Configuring IIS"
  Set-Location  IIS:\

  Write-Verbose "Configuring WebSite"
  $sitePath = "IIS:\Sites\$webSiteName"
  Write-Verbose $sitePath
  
  # always create an http and https binding
  $bindings = @(
    @{protocol="http";bindingInformation="*:80:$url"},
    @{protocol="https";bindingInformation="*:443:$url"})

    # if the site doesn't exist we should create it
  $site = Get-Item $sitePath -ErrorAction SilentlyContinue
  if (!$site) { 
    Write-Verbose " -> !!! Site does not exist, creating..."
    $id = (dir IIS:\Sites | foreach {$_.id} | sort -Descending | select -first 1) + 1
      
    # we set this to the web root to something
    # if you are using octopus then it will change it later on in the deployment
    # but we have to set it to something
    # so use the current directory for now
    $webRoot = (resolve-path .)
    New-Item $sitePath -bindings $bindings -id $id -physicalPath $webRoot
    $site = Get-Item $sitePath
  } else {
    Write-Verbose " -> Site already exists..."
  }

  Write-Verbose " -> Configuring Bindings"
  Set-ItemProperty $sitePath -name bindings -value $bindings

  Write-Verbose " -> Configure App Pool"
  Set-ItemProperty $sitePath -name applicationPool -value $appPoolName

  if ($configure) {
    &$configure
  }
  
  Write-Verbose "Successfully configured WebSite"
}

function Set-WindowsAuthentication() {
  [CmdLetBinding()]
  param (
    [Parameter(Mandatory=$true)] [bool] $enabled = $TRUE
  )

  Write-Verbose " -> Windows authentication $enabled"
  Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/windowsAuthentication -name enabled -value $enabled -location $site.name
}

function Set-AnonymousAuthentication() {
  [CmdLetBinding()]
  param (
    [Parameter(Mandatory=$true)] [bool] $enabled = $TRUE
  )

  Write-Verbose " -> Anonymous authentication $enabled"
  Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/anonymousAuthentication -name enabled -value $enabled -location $site.name
}

function Set-BasicAuthentication() {
  [CmdLetBinding()]
  param (
    [Parameter(Mandatory=$true)] [bool] $enabled = $TRUE
  )
 
  Write-Verbose " -> Basic authentication $enabled"
  Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/basicAuthentication -name enabled -value $enabled -location $site.name
}

function Add-MimeType() {
  <#
  .DESCRIPTION
  Binds a mime type to an extension in the static content IIS settings. This is required if you want to
  be able to serve custom content which is not served by IIS by default (for example web fonts with a .woff extension).

  .EXAMPLE
  Add-MimeType ".woff" "application/x-font-woff"
  #>

  [CmdLetBinding()]
  param (
    [Parameter(Mandatory=$true)] [string] $extension,
    [Parameter(Mandatory=$true)] [string] $mimeType
  )

  Write-Verbose "Adding MimeType: $extension -> $mimeType"

  Add-WebConfigurationProperty //staticContent -name collection -value @{fileExtension=$extension; mimeType=$mimeType} -location $site.name -ErrorAction Continue
}

function Get-WebPageContent() {
  <#
  .DESCRIPTION
  Gets the content of a web page with a given url. Uses the default credentials for the current
  user to make the request.  

  .EXAMPLE
  Get-WebPageContent "http://www.example.com"
  #>

  [CmdLetBinding()]
  param (
    [Parameter(Mandatory=$true)] [string] $url
  )

  Write-Verbose "Getting Url: $url"
    
  'create a web request'
  $webRequest = [System.Net.WebRequest]::Create($url)
  $webrequest.ContentLength = 0
  $webRequest.Credentials = [System.Net.CredentialCache]::DefaultCredentials
  $webRequest.Method = "GET"

  $response = $webRequest.GetResponse()
  $reader = new-object System.IO.StreamReader($response.GetResponseStream())
  $reader.ReadToEnd()
}