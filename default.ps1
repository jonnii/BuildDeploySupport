Framework "4.0"

task default -depends Package

task Clean {
	$dir = '.\output'
	if (test-path $dir) {
		rm -force -recurse $dir
    }
}

task Package -depends Clean {
	mkdir output
	$version = gc ./Version
	.\tools\nuget.exe pack ".\package\package.nuspec" -outputdirectory ".\output" -version $version
}

task PackagePre -depends Clean {
	mkdir output

	$version = gc ./Version
	$when = (get-date).ToString("yyyyMMddHHmmss")
	$preVersion = "$version-dev-$when"
	
	.\tools\nuget.exe pack ".\package\package.nuspec" -outputdirectory ".\output" -version $preVersion
}

task Publish -depends Package {
	$package = gci .\output\*.nupkg | select -first 1
	.\tools\nuget.exe Push $package.fullname
}

task PublishPre -depends PackagePre {
	$package = gci .\output\*.nupkg | select -first 1
	.\tools\nuget.exe Push $package.fullname
}