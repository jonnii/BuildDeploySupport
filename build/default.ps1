Framework "4.0"

task default -depends Package

task Clean {
	$dir = '.\..\output'
	if (test-path $dir) {
		rm -force -recurse $dir
    }
}

task Compile -depends Clean {
	$header = get-content header.txt

	cp -recurse ..\package ..\output\package
	ls ..\output -recurse -filter *.ps1 | foreach-object {
		$content = get-content $_.fullname
		($header + "`r`n" + $content) | set-content -path $_.fullname
	}
}

task Package -depends Compile {
	$version = gc .\..\Version
	.\..\tools\nuget.exe pack ".\..\output\package\package.nuspec" -outputdirectory ".\..\output" -version $version
}

task PackagePre -depends Compile {
	$version = gc .\..\Version
	$when = (get-date).ToString("yyyyMMddHHmmss")
	$preVersion = "$version-dev-$when"
	
	.\..\tools\nuget.exe pack ".\..\output\package\package.nuspec" -outputdirectory ".\..\output" -version $preVersion
}

task Publish -depends Package {
	$package = gci .\..\output\*.nupkg | select -first 1
	.\..\tools\nuget.exe Push $package.fullname
}

task PublishPre -depends PackagePre {
	$package = gci .\..\output\*.nupkg | select -first 1
	.\..\tools\nuget.exe Push $package.fullname
}