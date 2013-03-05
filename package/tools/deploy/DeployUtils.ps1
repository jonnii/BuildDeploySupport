###################################################
# DO NOT MODIFY THIS FILE, IT WILL BE OVERWRITTEN #
###################################################

# If you want to make changes please fork and contribute to the BuildDeploySupport 
# project on github, so everyone can take advantage of your changes!

function ReadXmlNode($filename, $xpath) {
    $xml = [xml](Get-Content $filename)
	$node = $xml.SelectNodes($xpath) | select -f 1
    
    if(!($node)){
        throw "could not find path $path"
    }
    
    return $node.innertext
}

function WriteXmlAttribute($filename, $xpath, $name, $value) {
	$xml = [xml](Get-Content $filename)
			
	$node = $xml.SelectNodes($xpath) | select -f 1
	
	if(!($node)){
        throw "could not find path $path"
    }

	$node.SetAttribute($name, $value)
	$xml.save($filename)
}