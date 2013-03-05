param($installPath, $toolsPath, $package)

# find out where to put the files, we're going to create a deploy directory
# at the same level as the solution.

$rootDir = (Get-Item $installPath).parent.parent.fullname
$deployTarget = "$rootDir\Deploy\Support\"

# create our deploy support directory if it doesn't exist yet

$deploySource = join-path $installPath 'tools/deploy'

if (!(test-path $deployTarget)) {
	mkdir $deployTarget
}

# copy everything in there

Copy-Item "$deploySource/*" $deployTarget -Recurse -Force

# get the active solution
$solution = Get-Interface $dte.Solution ([EnvDTE80.Solution2])

# create a deploy solution folder if it doesn't exist

$deployFolder = $solution.Projects | where-object { $_.ProjectName -eq "Deploy" } | select -first 1

if(!$deployFolder) {
	$deployFolder = $solution.AddSolutionFolder("Deploy")
}

# add all our support deploy scripts to our Support solution folder

$folderItems = Get-Interface $deployFolder.ProjectItems ([EnvDTE.ProjectItems])

ls $deployTarget | foreach-object { 
	$folderItems.AddFromFile($_.FullName) > $null
} > $null