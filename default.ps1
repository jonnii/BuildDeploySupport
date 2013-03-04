Framework "4.0"

task default -depends BuildPackage

task Clean {
	$dir = '.\build'
	if (test-path $dir) {
		rm -force -recurse $dir
    }
}

task BuildPackage -depends Clean {
	mkdir build
	.\tools\nuget.exe pack ".\package\package.nuspec" -outputdirectory ".\build"
}