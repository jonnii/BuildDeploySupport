Framework "4.0"

task default -depends Package

task Clean {
	$dir = '.\build'
	if (test-path $dir) {
		rm -force -recurse $dir
    }
}

task Package -depends Clean {
	mkdir build
	$version = gc ./Version
	.\tools\nuget.exe pack ".\package\package.nuspec" -outputdirectory ".\build" -version $version
}

task Publish -depends Package {
	$package = gci .\build\*.nupkg | select -first 1
	.\tools\nuget.exe Push $package.fullname
}